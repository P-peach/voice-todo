import 'dart:convert';

/// 待办事项数据模型
class TodoItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority; // '高', '中', '低'
  final bool isCompleted;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isVoiceCreated; // 是否通过语音创建

  TodoItem({
    required this.id,
    required this.title,
    this.description = '',
    this.category = '其他',
    this.priority = '中',
    this.isCompleted = false,
    this.deadline,
    required this.createdAt,
    this.completedAt,
    this.isVoiceCreated = false,
  });

  // 从数据库 Map 创建
  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '其他',
      priority: map['priority'] as String? ?? '中',
      isCompleted: (map['is_completed'] as int) == 1,
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      isVoiceCreated: (map['is_voice_created'] as int?) == 1,
    );
  }

  // 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'is_completed': isCompleted ? 1 : 0,
      'deadline': deadline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'is_voice_created': isVoiceCreated ? 1 : 0,
    };
  }

  // 从 JSON 创建（用于 Web 存储）
  factory TodoItem.fromJson(String json) {
    return TodoItem.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  // 转换为 JSON（用于 Web 存储）
  String toJson() {
    return jsonEncode(toMap());
  }

  // 复制并更新
  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? priority,
    bool? isCompleted,
    DateTime? deadline,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? isVoiceCreated,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      isVoiceCreated: isVoiceCreated ?? this.isVoiceCreated,
    );
  }

  // 标记为完成
  TodoItem markAsCompleted() {
    return copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
  }

  // 标记为未完成
  TodoItem markAsUncompleted() {
    return copyWith(
      isCompleted: false,
      completedAt: null,
    );
  }
}
