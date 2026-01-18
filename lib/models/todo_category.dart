/// 待办事项分类数据模型
class TodoCategory {
  final String name;
  final String icon;
  final String description;

  const TodoCategory({
    required this.name,
    required this.icon,
    this.description = '',
  });

  // 预定义的分类
  static const List<TodoCategory> predefinedCategories = [
    TodoCategory(
      name: '购物',
      icon: '🛒',
      description: '购物清单和商品购买',
    ),
    TodoCategory(
      name: '工作',
      icon: '💼',
      description: '工作任务和项目安排',
    ),
    TodoCategory(
      name: '生活',
      icon: '🏠',
      description: '日常生活和家务事项',
    ),
    TodoCategory(
      name: '学习',
      icon: '📚',
      description: '学习和自我提升',
    ),
    TodoCategory(
      name: '健康',
      icon: '❤️',
      description: '健康和运动计划',
    ),
    TodoCategory(
      name: '其他',
      icon: '📌',
      description: '其他类型的待办事项',
    ),
  ];

  // 根据名称获取分类
  static TodoCategory getByName(String name) {
    return predefinedCategories.firstWhere(
      (cat) => cat.name == name,
      orElse: () => predefinedCategories.last,
    );
  }

  // 从数据库 Map 创建
  factory TodoCategory.fromMap(Map<String, dynamic> map) {
    return TodoCategory(
      name: map['name'] as String,
      icon: map['icon'] as String,
      description: map['description'] as String? ?? '',
    );
  }

  // 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'description': description,
    };
  }
}
