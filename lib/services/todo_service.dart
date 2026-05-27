import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/models.dart';

/// CRUD for TODO items stored in the student's personal Firebase Firestore.
class TodoService {
  // Uses the default Firebase app (personal Firebase)
  FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
      );

  String? get _userId => FirebaseAuth.instanceFor(
        app: Firebase.app(),
      ).currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('todos');

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Stream of all todos belonging to the current user, newest first.
  Stream<List<Todo>> getTodos() {
    if (_userId == null) return const Stream.empty();
    return _collection
        .where('user_id', isEqualTo: _userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Todo.fromDoc).toList());
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  /// Add a new todo for the current user.
  Future<void> addTodo({
    required String title,
    String description = '',
  }) async {
    if (_userId == null) return;
    await _collection.add({
      'user_id': _userId,
      'title': title.trim(),
      'description': description.trim(),
      'is_done': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  /// Toggle the done/undone state of a todo.
  Future<void> toggleDone(String todoId, bool currentValue) async {
    await _collection.doc(todoId).update({'is_done': !currentValue});
  }

  /// Update title and description of a todo.
  Future<void> updateTodo(
    String todoId, {
    required String title,
    required String description,
  }) async {
    await _collection.doc(todoId).update({
      'title': title.trim(),
      'description': description.trim(),
    });
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  /// Permanently delete a todo.
  Future<void> deleteTodo(String todoId) async {
    await _collection.doc(todoId).delete();
  }
}
