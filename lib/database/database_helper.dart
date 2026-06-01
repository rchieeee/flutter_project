import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/todo.dart';

/// SQLite database helper — works on Android (native) and Web (WASM via
/// sqflite_common_ffi_web). All TODO operations go through this class so that
/// offline changes persist locally before being synced to Firebase.
class DatabaseHelper {
  static Database? _db;

  // ── Initialise ────────────────────────────────────────────────────────────

  /// Call once at app startup (before runApp).
  static Future<void> initialise() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
    _db ??= await _open();
  }

  static Future<Database> get _database async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    if (kIsWeb) {
      return openDatabase(
        'boiser_todos.db',
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, 'boiser_todos.db');
      return openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        is_done INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL DEFAULT 'low',
        category TEXT NOT NULL DEFAULT 'personal',
        due_date INTEGER,
        created_at INTEGER NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0,
        pending_action TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    // Future migrations go here
  }

  // ── INSERT ────────────────────────────────────────────────────────────────

  static Future<void> insertTodo(Map<String, dynamic> data) async {
    final db = await _database;
    await db.insert('todos', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── READ ──────────────────────────────────────────────────────────────────

  /// All non-deleted, non-pending-delete todos for this user.
  static Future<List<Map<String, dynamic>>> getTodos(String userId) async {
    final db = await _database;
    return db.query(
      'todos',
      where: 'user_id = ? AND pending_action != ? OR (user_id = ? AND pending_action IS NULL)',
      whereArgs: [userId, 'delete', userId],
      orderBy: 'created_at DESC',
    );
  }

  /// All todos regardless of state (used during sync).
  static Future<List<Map<String, dynamic>>> getAllTodosRaw(String userId) async {
    final db = await _database;
    return db.query(
      'todos',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  /// Only rows that need syncing to Firebase.
  static Future<List<Map<String, dynamic>>> getPendingSyncTodos(String userId) async {
    final db = await _database;
    return db.query(
      'todos',
      where: 'user_id = ? AND pending_sync = 1',
      whereArgs: [userId],
    );
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  static Future<void> updateTodo(String id, Map<String, dynamic> data) async {
    final db = await _database;
    await db.update('todos', data, where: 'id = ?', whereArgs: [id]);
  }

  /// Mark a row as fully synced (no pending action).
  static Future<void> markSynced(String id) async {
    final db = await _database;
    await db.update(
      'todos',
      {'pending_sync': 0, 'pending_action': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// After a Firebase add, update the local row id to the real Firestore id.
  static Future<void> updateLocalId(String oldId, String newId) async {
    final db = await _database;
    await db.execute(
      'UPDATE todos SET id = ?, pending_sync = 0, pending_action = NULL WHERE id = ?',
      [newId, oldId],
    );
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  static Future<void> deleteTodo(String id) async {
    final db = await _database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  /// Convert a DB row map back to a [Todo] model.
  static Todo rowToTodo(Map<String, dynamic> row) {
    return Todo(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      isDone: (row['is_done'] as int) == 1,
      isDeleted: (row['is_deleted'] as int) == 1,
      priority: row['priority'] as String? ?? 'low',
      category: row['category'] as String? ?? 'personal',
      dueDate: row['due_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['due_date'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  /// Convert a [Todo] to a row map.
  static Map<String, dynamic> todoToRow(
    Todo todo, {
    required String userId,
    bool pendingSync = false,
    String? pendingAction,
  }) {
    return {
      'id': todo.id,
      'user_id': userId,
      'title': todo.title,
      'description': todo.description,
      'is_done': todo.isDone ? 1 : 0,
      'is_deleted': todo.isDeleted ? 1 : 0,
      'priority': todo.priority,
      'category': todo.category,
      'due_date': todo.dueDate?.millisecondsSinceEpoch,
      'created_at': todo.createdAt.millisecondsSinceEpoch,
      'pending_sync': pendingSync ? 1 : 0,
      'pending_action': pendingAction,
    };
  }
}
