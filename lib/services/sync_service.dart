import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../database/database_helper.dart';
import '../core/connectivity_service.dart';

/// Watches connectivity and pushes any pending-sync SQLite rows up to
/// Firebase Firestore when the device comes back online.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  FirebaseFirestore get _db =>
      FirebaseFirestore.instanceFor(app: Firebase.app());
  String? get _userId =>
      FirebaseAuth.instanceFor(app: Firebase.app()).currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('todos');

  bool _isRunning = false;

  /// Start listening for connectivity changes and sync when online.
  void startListening() {
    ConnectivityService.onStatusChange.listen((isOnline) {
      if (isOnline && !_isRunning) {
        syncPending();
      }
    });
  }

  /// Push all pending-sync rows to Firebase. Safe to call multiple times.
  Future<void> syncPending() async {
    if (_isRunning) return;
    final uid = _userId;
    if (uid == null) return;

    _isRunning = true;
    try {
      final pending = await DatabaseHelper.getPendingSyncTodos(uid);
      for (final row in pending) {
        final action = row['pending_action'] as String?;
        final localId = row['id'] as String;

        try {
          switch (action) {
            case 'add':
              // Use a pre-determined Firestore doc ref so local and remote IDs match
              await _collection.doc(localId).set({
                'user_id': uid,
                'title': row['title'],
                'description': row['description'] ?? '',
                'is_done': (row['is_done'] as int) == 1,
                'is_deleted': (row['is_deleted'] as int) == 1,
                'priority': row['priority'] ?? 'low',
                'category': row['category'] ?? 'personal',
                'due_date': row['due_date'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        row['due_date'] as int)
                    : null,
                'created_at': FieldValue.serverTimestamp(),
              });
              await DatabaseHelper.markSynced(localId);
              break;

            case 'update':
              await _collection.doc(localId).update({
                'title': row['title'],
                'description': row['description'] ?? '',
                'is_done': (row['is_done'] as int) == 1,
                'is_deleted': (row['is_deleted'] as int) == 1,
                'priority': row['priority'] ?? 'low',
                'category': row['category'] ?? 'personal',
                'due_date': row['due_date'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        row['due_date'] as int)
                    : null,
              });
              await DatabaseHelper.markSynced(localId);
              break;

            case 'delete':
              await _collection.doc(localId).delete();
              await DatabaseHelper.deleteTodo(localId);
              break;

            default:
              await DatabaseHelper.markSynced(localId);
          }
        } catch (_) {
          // Leave as pending, will retry next time
        }
      }
    } finally {
      _isRunning = false;
    }
  }
}
