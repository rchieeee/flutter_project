import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../core/connectivity_service.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

/// Offline-first TODO service.
///
/// Every mutation writes to SQLite first (so it works offline).
/// If the device is online, it also writes straight to Firestore.
/// Pending offline changes are pushed to Firestore by [SyncService]
/// when connectivity is restored.
class TodoService {
  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app());

  FirebaseAuth get _auth => FirebaseAuth.instanceFor(app: Firebase.app());

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('todos');

  // ── Read ────────────────────────────────────────────────────────────────────

  /// Live stream of todos. Always reads from Firestore when online;
  /// falls back to SQLite when offline.
  Stream<List<Todo>> getAllTodos() {
    if (_userId == null) return const Stream.empty();
    return _collection
        .where('user_id', isEqualTo: _userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Todo.fromDoc).toList());
  }

  /// One-shot read from local SQLite — used when Firestore is unavailable.
  Future<List<Todo>> getLocalTodos() async {
    final uid = _userId;
    if (uid == null) return [];
    final rows = await DatabaseHelper.getAllTodosRaw(uid);
    return rows.map(DatabaseHelper.rowToTodo).toList();
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  Future<void> addTodo({
    required String title,
    String description = '',
    String priority = 'low',
    DateTime? dueDate,
    String category = 'personal',
  }) async {
    final uid = _userId;
    if (uid == null) return;

    final now = DateTime.now();
    // Pre-generate a Firestore-style doc ID so local & remote IDs match
    final docRef = _collection.doc();
    final id = docRef.id;

    final isOnline = await ConnectivityService.isOnline;

    // ── Always write to SQLite first ─────────────────────────────────────────
    await DatabaseHelper.insertTodo({
      'id': id,
      'user_id': uid,
      'title': title.trim(),
      'description': description.trim(),
      'is_done': 0,
      'is_deleted': 0,
      'priority': priority,
      'category': category,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'created_at': now.millisecondsSinceEpoch,
      'pending_sync': isOnline ? 0 : 1,
      'pending_action': isOnline ? null : 'add',
    });

    if (isOnline) {
      // ── Also write to Firestore ───────────────────────────────────────────
      await docRef.set({
        'user_id': uid,
        'title': title.trim(),
        'description': description.trim(),
        'is_done': false,
        'is_deleted': false,
        'created_at': FieldValue.serverTimestamp(),
        'priority': priority,
        'due_date': dueDate != null ? Timestamp.fromDate(dueDate) : null,
        'category': category,
      });
    }
  }

  // ── Update (shared helper) ──────────────────────────────────────────────────

  Future<void> _updateFlags(
    String todoId, {
    required Map<String, dynamic> firestoreData,
    required Map<String, dynamic> sqliteData,
  }) async {
    final uid = _userId;
    if (uid == null) return;

    final isOnline = await ConnectivityService.isOnline;

    // Write to SQLite immediately (optimistic)
    await DatabaseHelper.updateTodo(todoId, {
      ...sqliteData,
      'pending_sync': isOnline ? 0 : 1,
      'pending_action': isOnline ? null : 'update',
    });

    if (isOnline) {
      try {
        await _collection.doc(todoId).update(firestoreData);
      } catch (_) {
        // If Firestore fails, mark as pending so SyncService retries
        await DatabaseHelper.updateTodo(todoId, {
          'pending_sync': 1,
          'pending_action': 'update',
        });
      }
    }
  }

  Future<void> markDone(String todoId) => _updateFlags(
        todoId,
        firestoreData: {'is_done': true, 'is_deleted': false},
        sqliteData: {'is_done': 1, 'is_deleted': 0},
      );

  Future<void> markUndone(String todoId) => _updateFlags(
        todoId,
        firestoreData: {'is_done': false, 'is_deleted': false},
        sqliteData: {'is_done': 0, 'is_deleted': 0},
      );

  Future<void> softDelete(String todoId) => _updateFlags(
        todoId,
        firestoreData: {'is_deleted': true},
        sqliteData: {'is_deleted': 1},
      );

  Future<void> restore(String todoId) => _updateFlags(
        todoId,
        firestoreData: {'is_deleted': false, 'is_done': false},
        sqliteData: {'is_deleted': 0, 'is_done': 0},
      );

  Future<void> updateTodo(
    String todoId, {
    required String title,
    required String description,
    required String priority,
    DateTime? dueDate,
    required String category,
  }) =>
      _updateFlags(
        todoId,
        firestoreData: {
          'title': title.trim(),
          'description': description.trim(),
          'priority': priority,
          'due_date': dueDate != null ? Timestamp.fromDate(dueDate) : null,
          'category': category,
        },
        sqliteData: {
          'title': title.trim(),
          'description': description.trim(),
          'priority': priority,
          'due_date': dueDate?.millisecondsSinceEpoch,
          'category': category,
        },
      );

  // ── Delete ──────────────────────────────────────────────────────────────────

  Future<void> permanentDelete(String todoId) async {
    final uid = _userId;
    if (uid == null) return;

    final isOnline = await ConnectivityService.isOnline;

    if (isOnline) {
      await _collection.doc(todoId).delete();
      await DatabaseHelper.deleteTodo(todoId);
    } else {
      // Mark for deletion — SyncService will delete from Firestore later
      await DatabaseHelper.updateTodo(todoId, {
        'pending_sync': 1,
        'pending_action': 'delete',
      });
    }
  }

  Future<void> clearTrash() async {
    final uid = _userId;
    if (uid == null) return;

    final isOnline = await ConnectivityService.isOnline;

    if (isOnline) {
      final snap = await _collection
          .where('user_id', isEqualTo: uid)
          .where('is_deleted', isEqualTo: true)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
        await DatabaseHelper.deleteTodo(doc.id);
      }
    } else {
      // Mark all deleted todos for deletion sync later
      final rows = await DatabaseHelper.getAllTodosRaw(uid);
      for (final row in rows) {
        if ((row['is_deleted'] as int) == 1) {
          await DatabaseHelper.updateTodo(row['id'] as String, {
            'pending_sync': 1,
            'pending_action': 'delete',
          });
        }
      }
    }
  }
}
