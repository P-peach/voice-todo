import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

// 仅在非 Web 平台导入 FFI Web 实现
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as web_sqlite;

import '../models/todo_item.dart';

/// SQLite 数据库服务
class SqliteService {
  static final SqliteService instance = SqliteService._internal();

  static Database? _database;
  static bool _isInitialized = false;
  static bool _useWebStorage = false;

  // 数据库名称和版本
  static const String _databaseName = 'voice_todo.db';
  static const int _databaseVersion = 2;

  // Web 平台的 SharedPreferences 存储
  static const String _webTodosKey = 'voice_todo_todos';

  SqliteService._internal();

  /// 初始化数据库工厂（Web 平台需要）
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      // Web 平台：直接使用 SharedPreferences 作为存储方案
      print('Using SharedPreferences for Web platform storage');
      _useWebStorage = true;
    } else {
      // 其他平台：使用 FFI
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _isInitialized = true;
  }

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_useWebStorage) {
      // Web 后备方案：抛出异常，使用 Web 特定方法
      throw UnimplementedError('Use web-specific methods for Web platform');
    }
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    String path;

    if (kIsWeb) {
      // Web 平台：直接使用数据库名称
      path = _databaseName;
    } else {
      // 其他平台：使用文件系统路径
      final dbPath = await getDatabasesPath();
      path = join(dbPath, _databaseName);
    }

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ==================== Web 平台特定方法 ====================

  /// 获取 Web 存储的所有待办事项
  Future<List<TodoItem>> _getAllTodosWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = prefs.getStringList(_webTodosKey) ?? [];
    return todosJson
        .map((json) => TodoItem.fromJson(json))
        .toList();
  }

  /// 保存待办事项到 Web 存储
  Future<void> _saveTodosWeb(List<TodoItem> todos) async {
    final prefs = await SharedPreferences.getInstance();
    final todosJson = todos.map((todo) => todo.toJson()).toList();
    await prefs.setStringList(_webTodosKey, todosJson);
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT DEFAULT '其他',
        priority TEXT DEFAULT '中',
        is_completed INTEGER DEFAULT 0,
        deadline TEXT,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        is_voice_created INTEGER DEFAULT 0,
        reminder_config TEXT
      )
    ''');

    // 创建索引以提高查询性能
    await db.execute('''
      CREATE INDEX idx_todos_created_at ON todos(created_at DESC)
    ''');

    await db.execute('''
      CREATE INDEX idx_todos_category ON todos(category)
    ''');

    await db.execute('''
      CREATE INDEX idx_todos_completed ON todos(is_completed)
    ''');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 从版本 1 升级到版本 2：添加 reminder_config 字段
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE todos ADD COLUMN reminder_config TEXT
      ''');
    }
  }

  // ==================== 待办事项 CRUD 操作 ====================

  /// 插入待办事项
  Future<String> insertTodo(TodoItem todo) async {
    if (_useWebStorage) {
      final todos = await _getAllTodosWeb();
      todos.add(todo);
      await _saveTodosWeb(todos);
      return todo.id;
    }

    final db = await database;
    await db.insert('todos', todo.toMap());
    return todo.id;
  }

  /// 批量插入待办事项
  Future<void> insertTodos(List<TodoItem> todos) async {
    if (_useWebStorage) {
      final existingTodos = await _getAllTodosWeb();
      existingTodos.addAll(todos);
      await _saveTodosWeb(existingTodos);
      return;
    }

    final db = await database;
    final batch = db.batch();
    for (final todo in todos) {
      batch.insert('todos', todo.toMap());
    }
    await batch.commit(noResult: true);
  }

  /// 更新待办事项
  Future<void> updateTodo(TodoItem todo) async {
    if (_useWebStorage) {
      final todos = await _getAllTodosWeb();
      final index = todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        todos[index] = todo;
        await _saveTodosWeb(todos);
      }
      return;
    }

    final db = await database;
    await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  /// 删除待办事项
  Future<void> deleteTodo(String id) async {
    if (_useWebStorage) {
      final todos = await _getAllTodosWeb();
      todos.removeWhere((t) => t.id == id);
      await _saveTodosWeb(todos);
      return;
    }

    final db = await database;
    await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 批量删除待办事项
  Future<void> deleteTodos(List<String> ids) async {
    if (_useWebStorage) {
      final todos = await _getAllTodosWeb();
      todos.removeWhere((t) => ids.contains(t.id));
      await _saveTodosWeb(todos);
      return;
    }

    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.delete(
        'todos',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  /// 根据ID获取待办事项
  Future<TodoItem?> getTodoById(String id) async {
    if (_useWebStorage) {
      final todos = await _getAllTodosWeb();
      try {
        return todos.firstWhere((t) => t.id == id);
      } catch (e) {
        return null;
      }
    }

    final db = await database;
    final maps = await db.query(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return TodoItem.fromMap(maps.first);
  }

  /// 获取所有待办事项
  Future<List<TodoItem>> getAllTodos() async {
    if (_useWebStorage) {
      final todos = await _getAllTodosWeb();
      return todos..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final db = await database;
    final maps = await db.query(
      'todos',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  /// 获取未完成的待办事项
  Future<List<TodoItem>> getIncompleteTodos() async {
    if (_useWebStorage) {
      final todos = await _getAllTodosWeb();
      return todos
          .where((t) => !t.isCompleted)
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final db = await database;
    final maps = await db.query(
      'todos',
      where: 'is_completed = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  /// 获取已完成的待办事项
  Future<List<TodoItem>> getCompletedTodos() async {
    if (_useWebStorage) {
      final todos = await _getAllTodosWeb();
      return todos
          .where((t) => t.isCompleted)
          .toList()
          ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
    }

    final db = await database;
    final maps = await db.query(
      'todos',
      where: 'is_completed = ?',
      whereArgs: [1],
      orderBy: 'completed_at DESC',
    );
    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  /// 根据分类获取待办事项
  Future<List<TodoItem>> getTodosByCategory(String category) async {
    if (_useWebStorage) {
      final todos = await _getAllTodosWeb();
      return todos
          .where((t) => t.category == category)
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final db = await database;
    final maps = await db.query(
      'todos',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  /// 根据优先级获取待办事项
  Future<List<TodoItem>> getTodosByPriority(String priority) async {
    if (_useWebStorage) {
      final todos = await _getAllTodosWeb();
      return todos
          .where((t) => t.priority == priority)
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final db = await database;
    final maps = await db.query(
      'todos',
      where: 'priority = ?',
      whereArgs: [priority],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  /// 获取指定日期范围内的待办事项
  Future<List<TodoItem>> getTodosByDateRange(DateTime start, DateTime end) async {
    if (_useWebStorage) {
      final todos = await _getAllTodosWeb();
      return todos
          .where((t) =>
              t.createdAt.isAfter(start) && t.createdAt.isBefore(end))
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final db = await database;
    final maps = await db.query(
      'todos',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  /// 搜索待办事项
  Future<List<TodoItem>> searchTodos(String keyword) async {
    if (_useWebStorage) {
      final todos = await _getAllTodosWeb();
      final lowerKeyword = keyword.toLowerCase();
      return todos
          .where((t) =>
              t.title.toLowerCase().contains(lowerKeyword) ||
              t.description.toLowerCase().contains(lowerKeyword))
          .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    final db = await database;
    final maps = await db.query(
      'todos',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => TodoItem.fromMap(map)).toList();
  }

  /// 获取待办事项统计
  Future<Map<String, dynamic>> getTodoStatistics() async {
    if (_useWebStorage) {
      final todos = await _getAllTodosWeb();
      final totalCount = todos.length;
      final completedCount = todos.where((t) => t.isCompleted).length;
      final incompleteCount = totalCount - completedCount;

      // 按分类统计
      final Map<String, int> categoryStats = {};
      for (final todo in todos) {
        categoryStats[todo.category] = (categoryStats[todo.category] ?? 0) + 1;
      }

      return {
        'totalCount': totalCount,
        'completedCount': completedCount,
        'incompleteCount': incompleteCount,
        'categoryStats': categoryStats,
      };
    }

    final db = await database;

    // 总数
    final totalCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM todos',
    );
    final totalCount = Sqflite.firstIntValue(totalCountResult) ?? 0;

    // 未完成数量
    final incompleteResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM todos WHERE is_completed = 0',
    );
    final incompleteCount = Sqflite.firstIntValue(incompleteResult) ?? 0;

    // 已完成数量
    final completedCount = totalCount - incompleteCount;

    // 按分类统计
    final categoryResult = await db.rawQuery('''
      SELECT category, COUNT(*) as count
      FROM todos
      GROUP BY category
      ORDER BY count DESC
    ''');

    final Map<String, int> categoryStats = {};
    for (final row in categoryResult) {
      categoryStats[row['category'] as String] = row['count'] as int;
    }

    return {
      'totalCount': totalCount,
      'completedCount': completedCount,
      'incompleteCount': incompleteCount,
      'categoryStats': categoryStats,
    };
  }

  /// 清空所有待办事项
  Future<void> clearAllTodos() async {
    if (_useWebStorage) {
      await _saveTodosWeb([]);
      return;
    }

    final db = await database;
    await db.delete('todos');
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_useWebStorage) {
      // Web 存储不需要关闭
      return;
    }

    final db = await database;
    await db.close();
    _database = null;
  }
}
