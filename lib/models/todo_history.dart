/// 历史记录数据模型
class TodoHistory {
  final String date; // 格式: YYYY-MM-DD
  final DateTime dateTime;
  final List<TodoHistoryItem> items;

  TodoHistory({
    required this.date,
    required this.dateTime,
    required this.items,
  });

  // 完成的待办事项数量
  int get completedCount => items.where((item) => item.isCompleted).length;

  // 总待办事项数量
  int get totalCount => items.length;

  // 完成率 (0.0 - 1.0)
  double get completionRate {
    if (totalCount == 0) return 0.0;
    return completedCount / totalCount;
  }

  // 完成率评价
  String get rateLabel {
    if (completionRate >= 0.8) return '优秀';
    if (completionRate >= 0.5) return '良好';
    return '继续';
  }

  // 从待办事项列表创建历史记录
  factory TodoHistory.fromTodos(List<Map<String, dynamic>> todos) {
    if (todos.isEmpty) {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      return TodoHistory(
        date: dateStr,
        dateTime: now,
        items: [],
      );
    }

    // 按日期分组
    final Map<String, List<Map<String, dynamic>>> groupedTodos = {};
    for (final todo in todos) {
      final createdAt = DateTime.parse(todo['created_at'] as String);
      final dateStr =
          '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

      groupedTodos.putIfAbsent(dateStr, () => []);
      groupedTodos[dateStr]!.add(todo);
    }

    // 这里只返回第一天的历史记录
    // 实际使用时，应该遍历所有日期
    final firstDate = groupedTodos.keys.first;
    final items = groupedTodos[firstDate]!.map((todo) {
      return TodoHistoryItem(
        id: todo['id'] as String,
        title: todo['title'] as String,
        isCompleted: (todo['is_completed'] as int) == 1,
        category: todo['category'] as String? ?? '其他',
        completedAt: todo['completed_at'] != null
            ? DateTime.parse(todo['completed_at'] as String)
            : null,
      );
    }).toList();

    return TodoHistory(
      date: firstDate,
      dateTime: DateTime.parse(todos.first['created_at'] as String),
      items: items,
    );
  }

  // 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'datetime': dateTime.toIso8601String(),
    };
  }
}

/// 历史记录中的单个待办事项
class TodoHistoryItem {
  final String id;
  final String title;
  final bool isCompleted;
  final String category;
  final DateTime? completedAt;

  TodoHistoryItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.category,
    this.completedAt,
  });
}
