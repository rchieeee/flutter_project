import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/todo.dart';

/// Database helper that uses REAL SQLite for Android/iOS,
/// and an IN-MEMORY list for Web (Chrome) strictly for UI testing.
/// This prevents any WASM/Web Worker crashes on localhost.
class DatabaseHelper {
  static Database? _db;

  // ── IN-MEMORY MOCK FOR WEB UI TESTING ─────────────────────────────────────
  static final List<Map<String, dynamic>> _webMemoryDb = [];

  // ── Initialise ────────────────────────────────────────────────────────────

  static Future<void> initialise() async {
    if (kIsWeb) {
      // In web, we do nothing to initialize because we just use _webMemoryDb
      return;
    }
    _db ??= await _open();
  }

  static Future<Database> get _database async {
    if (kIsWeb) throw UnsupportedError('SQLite is disabled on Web for testing.');
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'boiser_todos.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
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

  // ── INSERT ────────────────────────────────────────────────────────────────

  static Future<void> insertTodo(Map<String, dynamic> data) async {
    if (kIsWeb) {
      // If it exists, replace it
      _webMemoryDb.removeWhere((row) => row['id'] == data['id']);
      _webMemoryDb.add(Map<String, dynamic>.from(data));
      return;
    }
    final db = await _database;
    await db.insert('todos', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── READ ──────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getTodos(String userId) async {
    if (kIsWeb) {
      final rows = _webMemoryDb.where((r) {
        return (r['user_id'] == userId && r['pending_action'] != 'delete') ||
               (r['user_id'] == userId && r['pending_action'] == null);
      }).toList();
      rows.sort((a, b) => (b['created_at'] as int).compareTo(a['created_at'] as int));
      return rows.map((r) => Map<String, dynamic>.from(r)).toList();
    }
    final db = await _database;
    return db.query(
      'todos',
      where: 'user_id = ? AND pending_action != ? OR (user_id = ? AND pending_action IS NULL)',
      whereArgs: [userId, 'delete', userId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> getAllTodosRaw(String userId) async {
    if (kIsWeb) {
      final rows = _webMemoryDb.where((r) => r['user_id'] == userId).toList();
      rows.sort((a, b) => (b['created_at'] as int).compareTo(a['created_at'] as int));
      return rows.map((r) => Map<String, dynamic>.from(r)).toList();
    }
    final db = await _database;
    return db.query(
      'todos',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingSyncTodos(String userId) async {
    if (kIsWeb) {
      return _webMemoryDb
          .where((r) => r['user_id'] == userId && r['pending_sync'] == 1)
          .map((r) => Map<String, dynamic>.from(r))
          .toList();
    }
    final db = await _database;
    return db.query(
      'todos',
      where: 'user_id = ? AND pending_sync = 1',
      whereArgs: [userId],
    );
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  static Future<void> updateTodo(String id, Map<String, dynamic> data) async {
    if (kIsWeb) {
      final index = _webMemoryDb.indexWhere((r) => r['id'] == id);
      if (index != -1) {
        final existing = _webMemoryDb[index];
        data.forEach((key, value) {
          existing[key] = value;
        });
      }
      return;
    }
    final db = await _database;
    await db.update('todos', data, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> markSynced(String id) async {
    if (kIsWeb) {
      final index = _webMemoryDb.indexWhere((r) => r['id'] == id);
      if (index != -1) {
        _webMemoryDb[index]['pending_sync'] = 0;
        _webMemoryDb[index]['pending_action'] = null;
      }
      return;
    }
    final db = await _database;
    await db.update(
      'todos',
      {'pending_sync': 0, 'pending_action': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> updateLocalId(String oldId, String newId) async {
    if (kIsWeb) {
      final index = _webMemoryDb.indexWhere((r) => r['id'] == oldId);
      if (index != -1) {
        _webMemoryDb[index]['id'] = newId;
        _webMemoryDb[index]['pending_sync'] = 0;
        _webMemoryDb[index]['pending_action'] = null;
      }
      return;
    }
    final db = await _database;
    await db.execute(
      'UPDATE todos SET id = ?, pending_sync = 0, pending_action = NULL WHERE id = ?',
      [newId, oldId],
    );
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  static Future<void> deleteTodo(String id) async {
    if (kIsWeb) {
      _webMemoryDb.removeWhere((r) => r['id'] == id);
      return;
    }
    final db = await _database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

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
