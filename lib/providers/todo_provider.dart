import 'package:flutter/material.dart';

import '../models/todo_item.dart';
import '../models/reminder_config.dart';
import '../services/sqlite_service.dart';
import '../services/notification_service.dart';

/// 待办事项状态管理 Provider
class TodoProvider extends ChangeNotifier {
  final SqliteService _sqliteService = SqliteService.instance;
  final NotificationService _notificationService = NotificationService.instance;

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
      // 验证必填字段
      if (!_validateTodo(todo)) {
        throw ArgumentError('待办事项缺少必填字段');
      }

      await _sqliteService.insertTodo(todo);
      
      // 如果有提醒配置，调度提醒
      if (todo.reminderConfig != null && todo.deadline != null) {
        await _scheduleReminders(todo);
      }
      
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow; // 重新抛出错误以便调用者处理
    }
  }

  /// 批量添加待办事项
  Future<void> addTodos(List<TodoItem> todos) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 验证所有待办事项
      for (final todo in todos) {
        if (!_validateTodo(todo)) {
          throw ArgumentError('待办事项 "${todo.title}" 缺少必填字段');
        }
      }

      // 按顺序保存待办事项
      await _sqliteService.insertTodos(todos);
      
      // 为有提醒配置的待办事项调度提醒
      for (final todo in todos) {
        if (todo.reminderConfig != null && todo.deadline != null) {
          await _scheduleReminders(todo);
        }
      }
      
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow; // 重新抛出错误以便调用者处理
    }
  }

  /// 设置提醒
  /// 
  /// [todoId] 待办事项 ID
  /// [count] 提醒次数
  /// [interval] 提醒间隔
  Future<void> setReminder({
    required String todoId,
    required int count,
    required Duration interval,
  }) async {
    try {
      final todo = await _sqliteService.getTodoById(todoId);
      if (todo == null) {
        throw ArgumentError('待办事项不存在');
      }

      if (todo.deadline == null) {
        throw ArgumentError('待办事项没有截止日期，无法设置提醒');
      }

      // 创建提醒配置
      final reminderConfig = ReminderConfig(
        count: count,
        interval: interval,
      );

      // 调度提醒并获取已调度的时间
      final scheduledTimes = await _notificationService.scheduleMultipleReminders(
        todoId: todo.id.hashCode, // 使用 hashCode 作为数字 ID
        title: todo.title,
        deadline: todo.deadline!,
        count: count,
        interval: interval,
      );

      // 更新提醒配置，包含已调度的时间
      final updatedConfig = reminderConfig.copyWith(
        scheduledTimes: scheduledTimes,
      );

      // 更新待办事项
      final updatedTodo = todo.copyWith(reminderConfig: updatedConfig);
      await _sqliteService.updateTodo(updatedTodo);
      
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 取消提醒
  /// 
  /// [todoId] 待办事项 ID
  Future<void> cancelReminder(String todoId) async {
    try {
      final todo = await _sqliteService.getTodoById(todoId);
      if (todo == null) {
        throw ArgumentError('待办事项不存在');
      }

      // 取消所有提醒
      await _notificationService.cancelAllRemindersForTodo(
        todo.id.hashCode,
        count: todo.reminderConfig?.count ?? 10,
      );

      // 移除提醒配置
      final updatedTodo = todo.copyWith(reminderConfig: null);
      await _sqliteService.updateTodo(updatedTodo);
      
      await loadTodos();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// 验证待办事项必填字段
  bool _validateTodo(TodoItem todo) {
    // 验证 id、title、createdAt 是否存在
    return todo.id.isNotEmpty && 
           todo.title.isNotEmpty && 
           todo.createdAt != null;
  }

  /// 调度提醒（私有方法）
  Future<void> _scheduleReminders(TodoItem todo) async {
    if (todo.reminderConfig == null || todo.deadline == null) {
      return;
    }

    final scheduledTimes = await _notificationService.scheduleMultipleReminders(
      todoId: todo.id.hashCode,
      title: todo.title,
      deadline: todo.deadline!,
      count: todo.reminderConfig!.count,
      interval: todo.reminderConfig!.interval,
    );

    // 更新待办事项的 scheduledTimes
    if (scheduledTimes.isNotEmpty) {
      final updatedConfig = todo.reminderConfig!.copyWith(
        scheduledTimes: scheduledTimes,
      );
      final updatedTodo = todo.copyWith(reminderConfig: updatedConfig);
      await _sqliteService.updateTodo(updatedTodo);
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
      // 获取待办事项以取消提醒
      final todo = await _sqliteService.getTodoById(id);
      if (todo != null && todo.reminderConfig != null) {
        await _notificationService.cancelAllRemindersForTodo(
          todo.id.hashCode,
          count: todo.reminderConfig!.count,
        );
      }
      
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
      // 取消所有待办事项的提醒
      for (final id in ids) {
        final todo = await _sqliteService.getTodoById(id);
        if (todo != null && todo.reminderConfig != null) {
          await _notificationService.cancelAllRemindersForTodo(
            todo.id.hashCode,
            count: todo.reminderConfig!.count,
          );
        }
      }
      
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
