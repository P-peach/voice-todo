import '../models/todo_item.dart';
import 'parsers/date_time_parser.dart';
import 'parsers/category_classifier.dart';
import 'parsers/list_mode_detector.dart';

/// 待办事项智能解析服务
///
/// 从语音识别的文本中智能解析待办事项
class TodoParserService {
  static final TodoParserService instance = TodoParserService._internal();

  final DateTimeParser _dateTimeParser = DateTimeParser();
  final CategoryClassifier _categoryClassifier = CategoryClassifier();
  final ListModeDetector _listModeDetector = ListModeDetector();
  
  // ID 生成计数器，确保在同一毫秒内生成的 ID 也是唯一的
  int _idCounter = 0;

  TodoParserService._internal();

  /// 解析语音文本，返回待办事项列表
  List<TodoItem> parse(String text) {
    if (text.trim().isEmpty) return [];

    // 检测是否为列表模式
    if (_listModeDetector.isListMode(text)) {
      return _parseListMode(text);
    }

    // 检测是否包含多个待办事项（用分隔符分割）
    final todos = <TodoItem>[];
    final segments = _splitMultipleTodos(text);

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

  /// 分割多个待办事项
  List<String> _splitMultipleTodos(String text) {
    // 尝试多种分隔符
    final separators = ['，', ',', '；', ';', '。', '.', '\n'];
    var segments = [text];

    for (final sep in separators) {
      segments = segments.expand((seg) => seg.split(sep)).toList();
    }

    return segments;
  }

  /// 解析列表模式的待办事项
  List<TodoItem> _parseListMode(String text) {
    final items = _listModeDetector.splitItems(text);
    final sharedAttrs = _listModeDetector.extractSharedAttributes(text);

    final todos = <TodoItem>[];
    for (final item in items) {
      // 直接使用分割后的项作为标题（已包含数量信息）
      final title = item.trim();
      if (title.isEmpty) continue;

      // 使用共享属性或从文本中提取
      final category = sharedAttrs['category'] as String? ?? 
                      _categoryClassifier.classify(text);
      final priority = sharedAttrs['priority'] as String? ?? 
                      _categoryClassifier.classifyPriority(text);
      final deadline = sharedAttrs['deadline'] as DateTime? ?? 
                      _dateTimeParser.parse(text);

      todos.add(TodoItem(
        id: _generateId(),
        title: title,
        description: '',
        category: category,
        priority: priority,
        deadline: deadline,
        createdAt: DateTime.now(),
        isVoiceCreated: true,
      ));
    }

    return todos;
  }

  /// 解析单个待办事项
  TodoItem? _parseSingleTodo(String text) {
    if (text.isEmpty) return null;

    final title = _extractTitle(text);
    if (title.isEmpty) return null;

    // 使用集成的解析器提取信息
    final category = _categoryClassifier.classify(text);
    final priority = _categoryClassifier.classifyPriority(text);
    final deadline = _dateTimeParser.parse(text);
    final needsReminder = _needsReminder(text);

    return TodoItem(
      id: _generateId(),
      title: title,
      description: '',
      category: category,
      priority: priority,
      deadline: deadline,
      createdAt: DateTime.now(),
      isVoiceCreated: true,
    );
  }

  /// 提取标题
  String _extractTitle(String text) {
    // 移除时间表达式、分类关键词、优先级关键词
    String title = text.trim();

    // 简单处理：取第一个标点符号之前的部分，或整段
    final firstPunctuation = title.indexOf(RegExp('[，。；,.;]'));
    if (firstPunctuation > 0) {
      title = title.substring(0, firstPunctuation).trim();
    }

    return title;
  }

  /// 检测是否需要提醒
  bool _needsReminder(String text) {
    final reminderKeywords = ['提醒我', '提醒', '记得', '别忘了', '别忘记'];
    return reminderKeywords.any((keyword) => text.contains(keyword));
  }

  /// 生成唯一ID
  String _generateId() {
    // 使用时间戳 + 计数器确保唯一性
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _idCounter++;
    return '${timestamp}_$_idCounter';
  }

  /// 智能补充文本（基于上下文）
  String? smartComplete(String partial) {
    // 这里可以实现智能提示功能
    // 基于用户历史记录、常用词汇等
    return null;
  }
}
