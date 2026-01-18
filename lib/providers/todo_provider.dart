import 'package:flutter/material.dart';

import '../models/todo_item.dart';
import '../services/sqlite_service.dart';

/// 待办事项状态管理 Provider
class TodoProvider extends ChangeNotifier {
  final SqliteService _sqliteService = SqliteService.instance;

  // 状态
  List<TodoItem> _todos = [];
  List<TodoItem> _incompleteTodos = [];
  List<TodoItem> _completedTodos = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TodoItem> get todos => _todos;
  List<TodoItem> get incompleteTodos => _incompleteTodos;
  List<TodoItem> get completedTodos => _completedTodos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 统计数据
  int get totalCount => _todos.length;
  int get incompleteCount => _incompleteTodos.length;
  int get completedCount => _completedTodos.length;
  double get completionRate {
    if (totalCount == 0) return 0.0;
    return completedCount / totalCount;
  }

  TodoProvider() {
    loadTodos();
  }

  /// 加载所有待办事项
  Future<void> loadTodos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todos = await _sqliteService.getAllTodos();
      _incompleteTodos = await _sqliteService.getIncompleteTodos();
      _completedTodos = await _sqliteService.getCompletedTodos();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 添加待办事项
  Future<void> addTodo(TodoItem todo) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _sqliteService.insertTodo(todo);
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 批量添加待办事项
  Future<void> addTodos(List<TodoItem> todos) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _sqliteService.insertTodos(todos);
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 更新待办事项
  Future<void> updateTodo(TodoItem todo) async {
    try {
      await _sqliteService.updateTodo(todo);
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 删除待办事项
  Future<void> deleteTodo(String id) async {
    try {
      await _sqliteService.deleteTodo(id);
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 批量删除待办事项
  Future<void> deleteTodos(List<String> ids) async {
    try {
      await _sqliteService.deleteTodos(ids);
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 标记为完成
  Future<void> markAsCompleted(String id) async {
    try {
      final todo = await _sqliteService.getTodoById(id);
      if (todo != null) {
        final updatedTodo = todo.markAsCompleted();
        await _sqliteService.updateTodo(updatedTodo);
        await loadTodos();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 标记为未完成
  Future<void> markAsUncompleted(String id) async {
    try {
      final todo = await _sqliteService.getTodoById(id);
      if (todo != null) {
        final updatedTodo = todo.markAsUncompleted();
        await _sqliteService.updateTodo(updatedTodo);
        await loadTodos();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 根据分类筛选
  Future<void> filterByCategory(String category) async {
    _isLoading = true;
    notifyListeners();

    try {
      _todos = await _sqliteService.getTodosByCategory(category);
      _incompleteTodos = _todos.where((todo) => !todo.isCompleted).toList();
      _completedTodos = _todos.where((todo) => todo.isCompleted).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 根据优先级筛选
  Future<void> filterByPriority(String priority) async {
    _isLoading = true;
    notifyListeners();

    try {
      _todos = await _sqliteService.getTodosByPriority(priority);
      _incompleteTodos = _todos.where((todo) => !todo.isCompleted).toList();
      _completedTodos = _todos.where((todo) => todo.isCompleted).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 搜索待办事项
  Future<void> searchTodos(String keyword) async {
    _isLoading = true;
    notifyListeners();

    try {
      _todos = await _sqliteService.searchTodos(keyword);
      _incompleteTodos = _todos.where((todo) => !todo.isCompleted).toList();
      _completedTodos = _todos.where((todo) => todo.isCompleted).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 重置筛选（显示所有）
  Future<void> resetFilter() async {
    await loadTodos();
  }

  /// 清空所有待办事项
  Future<void> clearAll() async {
    try {
      await _sqliteService.clearAllTodos();
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
