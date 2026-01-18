import '../models/todo_item.dart';

/// 待办事项智能解析服务
///
/// 从语音识别的文本中智能解析待办事项
class TodoParserService {
  static final TodoParserService instance = TodoParserService._internal();

  // 关键词映射
  static const Map<String, String> categoryKeywords = {
    '购物': '购物',
    '买': '购物',
    '超市': '购物',
    '商店': '购物',
    '商店街': '购物',
    '工作': '工作',
    '开会': '工作',
    '报告': '工作',
    '项目': '工作',
    '任务': '工作',
    '生活': '生活',
    '打扫': '生活',
    '做饭': '生活',
    '家务': '生活',
    '洗衣': '生活',
    '学习': '学习',
    '看书': '学习',
    '阅读': '学习',
    '课程': '学习',
    '练习': '学习',
    '健康': '健康',
    '运动': '健康',
    '锻炼': '健康',
    '健身': '健康',
    '跑步': '健康',
  };

  static const Map<String, String> priorityKeywords = {
    '紧急': '高',
    '重要': '高',
    '马上': '高',
    '立即': '高',
    '尽快': '高',
    '不急': '低',
    '慢慢': '低',
    '以后': '低',
    '有空': '低',
  };

  TodoParserService._internal();

  /// 解析语音文本，返回待办事项列表
  List<TodoItem> parse(String text) {
    if (text.trim().isEmpty) return [];

    final todos = <TodoItem>[];

    // 尝试多种分隔符
    final separators = ['，', ',', '；', ';', '。', '.', '\n'];
    var segments = [text];

    for (final sep in separators) {
      segments = segments.expand((seg) => seg.split(sep)).toList();
    }

    // 过滤空片段并解析
    for (final segment in segments) {
      final trimmed = segment.trim();
      if (trimmed.isNotEmpty) {
        final todo = _parseSingleTodo(trimmed);
        if (todo != null) {
          todos.add(todo);
        }
      }
    }

    return todos;
  }

  /// 解析单个待办事项
  TodoItem? _parseSingleTodo(String text) {
    if (text.isEmpty) return null;

    // 提取标题（第一个标点符号之前的部分，或整段）
    String title;
    String description = '';

    final firstPunctuation = text.indexOf(RegExp('[，。；,.;]'));
    if (firstPunctuation > 0) {
      title = text.substring(0, firstPunctuation).trim();
      description = text.substring(firstPunctuation + 1).trim();
    } else {
      title = text.trim();
    }

    // 如果标题太短，可能是误分割，合并到描述中
    if (title.length < 2 && description.isNotEmpty) {
      title = '$title $description'.trim();
      description = '';
    }

    return TodoItem(
      id: _generateId(),
      title: title,
      description: description,
      category: _extractCategory(text),
      priority: _extractPriority(text),
      createdAt: DateTime.now(),
      isVoiceCreated: true,
    );
  }

  /// 提取分类
  String _extractCategory(String text) {
    for (final entry in categoryKeywords.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    return '其他';
  }

  /// 提取优先级
  String _extractPriority(String text) {
    for (final entry in priorityKeywords.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    return '中';
  }

  /// 生成唯一ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 智能补充文本（基于上下文）
  String? smartComplete(String partial) {
    // 这里可以实现智能提示功能
    // 基于用户历史记录、常用词汇等
    return null;
  }
}
