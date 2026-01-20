# Design Document: Native Voice Recognition

## Overview

本设计文档描述了原生语音识别待办事项系统的架构和实现细节。该系统将接入 iOS 和 Android 的原生 ASR 服务，实现实时语音识别，并通过智能解析引擎自动提取待办事项的标题、分类、优先级、截止日期和提醒配置，最终自动创建并保存待办事项到本地数据库。

系统采用分层架构，将语音识别、文本解析、数据持久化和 UI 展示分离，确保各模块职责清晰、易于测试和维护。

## Architecture

系统采用三层架构：

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ VoiceProvider│  │ TodoProvider │  │ UI Components│  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│                     Business Layer                       │
│  ┌──────────────────┐  ┌──────────────────────────┐    │
│  │ VoiceRecognition │  │   TodoParserService      │    │
│  │     Service      │  │  ┌────────────────────┐  │    │
│  │                  │  │  │ DateTimeParser     │  │    │
│  │                  │  │  │ CategoryClassifier │  │    │
│  │                  │  │  │ ListModeDetector   │  │    │
│  └──────────────────┘  └──┴────────────────────┴──┘    │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ SQLiteService│  │ Notification │  │ Platform     │  │
│  │              │  │   Service    │  │  Channels    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 层次职责

**Presentation Layer（展示层）**
- 管理 UI 状态和用户交互
- 通过 Provider 模式管理状态
- 响应用户输入并触发业务逻辑

**Business Layer（业务层）**
- 封装核心业务逻辑
- 语音识别服务：调用平台原生 ASR API
- 解析服务：智能提取待办事项信息

**Data Layer（数据层）**
- 数据持久化（SQLite）
- 本地通知调度
- 平台原生功能调用

## Components and Interfaces

### 1. VoiceRecognitionService

语音识别服务，封装平台原生 ASR API。

```dart
class VoiceRecognitionService {
  // 单例模式
  static final VoiceRecognitionService instance;
  
  // 初始化服务
  Future<void> initialize();
  
  // 检查权限
  Future<PermissionStatus> checkPermissions();
  
  // 请求权限
  Future<bool> requestPermissions();
  
  // 开始识别
  Future<void> startListening({
    String locale = 'zh_CN',
    Function(String)? onResult,
    Function(String)? onError,
  });
  
  // 停止识别
  Future<String> stopListening();
  
  // 取消识别
  Future<void> cancelListening();
  
  // 状态流
  Stream<VoiceStatus> get statusStream;
  
  // 实时结果流
  Stream<String> get resultStream;
  
  // 错误流
  Stream<String> get errorStream;
  
  // 当前状态
  bool get isListening;
  bool get isAvailable;
}
```

**平台实现**

使用 `speech_to_text` 包（[pub.dev](https://pub.dev/packages/speech_to_text)），该包封装了：
- iOS: SFSpeechRecognizer
- Android: SpeechRecognizer

### 2. TodoParserService

待办事项解析服务，从识别文本中提取结构化信息。

```dart
class TodoParserService {
  // 单例模式
  static final TodoParserService instance;
  
  // 解析文本，返回待办事项列表
  List<TodoItem> parse(String text);
  
  // 检测是否为列表模式
  bool isListMode(String text);
  
  // 私有方法
  TodoItem _parseSingleTodo(String text);
  String _extractTitle(String text);
  String _extractCategory(String text);
  String _extractPriority(String text);
  DateTime? _extractDeadline(String text);
  bool _needsReminder(String text);
}
```

### 3. DateTimeParser

日期时间解析器，将自然语言转换为 DateTime 对象。

```dart
class DateTimeParser {
  // 解析日期时间表达式
  DateTime? parse(String text);
  
  // 解析相对日期（今天、明天、后天）
  DateTime? _parseRelativeDate(String text);
  
  // 解析星期表达式（下周一、下周五）
  DateTime? _parseWeekday(String text);
  
  // 解析天数偏移（三天后、一周后）
  DateTime? _parseDayOffset(String text);
  
  // 解析时间段（上午、下午、晚上）
  TimeOfDay? _parseTimeOfDay(String text);
  
  // 解析具体时间（10点、下午3点）
  TimeOfDay? _parseSpecificTime(String text);
}
```

### 4. CategoryClassifier

分类识别器，根据关键词识别待办事项分类。

```dart
class CategoryClassifier {
  // 关键词映射表
  static const Map<String, List<String>> categoryKeywords = {
    '工作': ['会议', '报告', '项目', '巡检', '进货', '任务'],
    '购物': ['买', '购买', '超市', '商店', '购物'],
    '学习': ['学习', '阅读', '课程', '练习', '复习'],
    '生活': ['打扫', '做饭', '洗衣', '生日', '提醒', '家务'],
    '健康': ['运动', '锻炼', '健身', '跑步', '瑜伽'],
  };
  
  // 优先级关键词
  static const Map<String, List<String>> priorityKeywords = {
    '高': ['紧急', '重要', '马上', '立即', '尽快'],
    '低': ['不急', '有空', '以后', '慢慢'],
  };
  
  // 识别分类
  String classify(String text);
  
  // 识别优先级
  String classifyPriority(String text);
}
```

### 5. ListModeDetector

列表模式检测器，识别并分割列表式待办事项。

```dart
class ListModeDetector {
  // 检测是否为列表模式
  bool isListMode(String text);
  
  // 分割列表项
  List<String> splitItems(String text);
  
  // 提取共享属性（时间、分类）
  Map<String, dynamic> extractSharedAttributes(String text);
  
  // 提取数量信息
  String? extractQuantity(String item);
}
```

### 6. NotificationService

本地通知服务，管理待办事项提醒。

```dart
class NotificationService {
  // 单例模式
  static final NotificationService instance;
  
  // 初始化服务
  Future<void> initialize();
  
  // 调度单次提醒
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  });
  
  // 调度多次提醒
  Future<void> scheduleMultipleReminders({
    required int todoId,
    required String title,
    required DateTime deadline,
    required int count,
    required Duration interval,
  });
  
  // 取消提醒
  Future<void> cancelReminder(int id);
  
  // 取消待办事项的所有提醒
  Future<void> cancelAllRemindersForTodo(int todoId);
}
```

**平台实现**

使用 `flutter_local_notifications` 包（[pub.dev](https://pub.dev/packages/flutter_local_notifications)）。

### 7. VoiceProvider

语音识别状态管理。

```dart
class VoiceProvider extends ChangeNotifier {
  VoiceRecognitionService _service;
  TodoParserService _parser;
  
  // 状态
  VoiceStatus _status;
  String _recognizedText;
  String? _error;
  
  // Getters
  VoiceStatus get status;
  String get recognizedText;
  String? get error;
  bool get isListening;
  
  // 方法
  Future<void> startListening();
  Future<List<TodoItem>> stopListening();
  Future<void> cancelListening();
  void clearError();
}
```

## Data Models

### TodoItem

```dart
class TodoItem {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String priority;
  final DateTime? deadline;
  final DateTime createdAt;
  final bool isCompleted;
  final bool isVoiceCreated;
  final ReminderConfig? reminderConfig;
  
  TodoItem({
    required this.id,
    required this.title,
    this.description,
    this.category = '其他',
    this.priority = '中',
    this.deadline,
    required this.createdAt,
    this.isCompleted = false,
    this.isVoiceCreated = false,
    this.reminderConfig,
  });
  
  // 序列化方法
  Map<String, dynamic> toJson();
  factory TodoItem.fromJson(Map<String, dynamic> json);
}
```

### ReminderConfig

```dart
class ReminderConfig {
  final int count;           // 提醒次数
  final Duration interval;   // 提醒间隔
  final List<DateTime> scheduledTimes; // 已调度的提醒时间
  
  ReminderConfig({
    required this.count,
    required this.interval,
    this.scheduledTimes = const [],
  });
  
  // 序列化方法
  Map<String, dynamic> toJson();
  factory ReminderConfig.fromJson(Map<String, dynamic> json);
}
```

### VoiceStatus

```dart
enum VoiceStatus {
  uninitialized,  // 未初始化
  ready,          // 准备就绪
  listening,      // 录音中
  processing,     // 处理中
  done,           // 完成
  error,          // 错误
}
```

### PermissionStatus

```dart
enum PermissionStatus {
  granted,        // 已授权
  denied,         // 已拒绝
  permanentlyDenied, // 永久拒绝
  notDetermined,  // 未确定
}
```

## Error Handling

### 错误类型

```dart
enum VoiceErrorType {
  permissionDenied,      // 权限被拒绝
  notAvailable,          // 服务不可用
  networkError,          // 网络错误
  timeout,               // 超时
  noSpeech,              // 未检测到语音
  recognitionFailed,     // 识别失败
  parsingFailed,         // 解析失败
}
```

### 错误处理策略

1. **权限错误**
   - 显示权限说明对话框
   - 提供跳转到设置页面的按钮
   - 记录权限请求历史

2. **识别错误**
   - 显示友好的错误提示
   - 提供重试按钮
   - 保留已识别的部分文本

3. **解析错误**
   - 显示原始识别文本
   - 允许用户手动编辑
   - 提供默认值填充

4. **数据库错误**
   - 记录错误日志
   - 显示保存失败提示
   - 提供重试机制

## Testing Strategy

### 单元测试

使用 Flutter 的 `test` 包编写单元测试。

**测试覆盖范围：**
- DateTimeParser: 测试各种日期时间表达式的解析
- CategoryClassifier: 测试分类和优先级识别
- ListModeDetector: 测试列表模式检测和分割
- TodoParserService: 测试完整的解析流程

**示例测试：**
```dart
test('解析"明天上午"应返回明天上午10点', () {
  final parser = DateTimeParser();
  final result = parser.parse('明天上午');
  
  expect(result, isNotNull);
  expect(result!.day, DateTime.now().add(Duration(days: 1)).day);
  expect(result.hour, 10);
});
```

### 集成测试

使用 `integration_test` 包测试完整流程。

**测试场景：**
1. 语音识别 → 解析 → 保存 → 显示
2. 列表模式识别 → 分割 → 批量保存
3. 提醒设置 → 通知调度 → 通知触发

### 属性测试

使用 `test` 包的 property-based testing 功能。

**测试属性将在下一节定义。**

## Correctness Properties

*属性是一种特征或行为，应该在系统的所有有效执行中保持为真——本质上是关于系统应该做什么的形式化陈述。属性作为人类可读规范和机器可验证正确性保证之间的桥梁。*


### Property 1: 服务初始化状态一致性
*对于任何*设备环境，当 Voice_Recognition_Service 初始化后，其 isAvailable 状态应与设备实际支持情况一致。
**Validates: Requirements 1.1**

### Property 2: 权限请求正确性
*对于任何*权限状态，当设备支持语音识别时，Voice_Recognition_Service 应正确请求必要的权限。
**Validates: Requirements 1.2**

### Property 3: 错误信息明确性
*对于任何*错误场景（设备不支持、权限被拒绝），Voice_Recognition_Service 应返回明确的错误信息。
**Validates: Requirements 1.6**

### Property 4: 实时识别流连续性
*对于任何*识别会话，当用户说话时，resultStream 应持续发出识别结果事件。
**Validates: Requirements 2.2, 2.3**

### Property 5: 停止识别返回最终结果
*对于任何*识别会话，当调用 stopListening 后，应返回完整的最终识别结果。
**Validates: Requirements 2.4**

### Property 6: 错误流正确传递
*对于任何*识别过程中的错误，errorStream 应正确发送错误信息。
**Validates: Requirements 2.5**

### Property 7: 标题提取完整性
*对于任何*识别文本，Parser_Service 应能提取出非空的待办事项标题。
**Validates: Requirements 3.1**

### Property 8: 时间表达式解析正确性
*对于任何*包含时间表达式的文本，Parser_Service 应正确解析并提取截止日期。
**Validates: Requirements 3.2, 4.2, 4.4, 4.5, 4.6, 4.7**

### Property 9: 分类识别正确性
*对于任何*包含分类关键词的文本，Parser_Service 应设置正确的待办事项分类。
**Validates: Requirements 3.3, 5.1, 5.2, 5.3, 5.4, 5.5**

### Property 10: 优先级识别正确性
*对于任何*包含优先级关键词的文本，Parser_Service 应设置正确的优先级。
**Validates: Requirements 3.4, 5.6, 5.7**

### Property 11: 多待办分割正确性
*对于任何*包含多个待办事项的文本，Parser_Service 应正确分割并分别解析每个待办事项。
**Validates: Requirements 3.5**

### Property 12: 列表模式分割正确性
*对于任何*列表式文本（如"苹果两箱，茼蒿10把，草莓"），Parser_Service 应按品类分割为多个独立的 TodoItem。
**Validates: Requirements 3.6, 10.1, 10.2, 10.3**

### Property 13: 返回类型正确性
*对于任何*识别文本，Parser_Service 的 parse 方法应返回 List<TodoItem> 类型。
**Validates: Requirements 3.7**

### Property 14: 无时间表达式默认行为
*对于任何*不包含时间表达式的文本，Parser_Service 应将截止日期设置为 null。
**Validates: Requirements 4.8**

### Property 15: 无关键词默认值
*对于任何*不包含分类或优先级关键词的文本，Parser_Service 应使用默认值。
**Validates: Requirements 5.8**

### Property 16: 数据验证完整性
*对于任何*TodoItem 列表，System 应验证每个待办事项的必填字段（id、title、createdAt）。
**Validates: Requirements 6.1**

### Property 17: 数据持久化成功性
*对于任何*验证通过的 TodoItem，System 应成功将其保存到 SQLite 数据库。
**Validates: Requirements 6.2**

### Property 18: 保存失败错误处理
*对于任何*保存失败的场景，System 应显示错误提示并保留原始识别文本。
**Validates: Requirements 6.4**

### Property 19: 批量保存顺序性
*对于任何*多个待办事项，System 应按顺序逐个保存，保持原始顺序。
**Validates: Requirements 6.5**

### Property 20: 超时自动停止
*对于任何*识别会话，当超过最大时长（60秒）时，System 应自动停止并处理结果。
**Validates: Requirements 9.4**

### Property 21: 数量信息保留
*对于任何*包含数量信息的品类（如"苹果两箱"），Parser_Service 应将数量信息包含在标题或描述中。
**Validates: Requirements 10.4**

### Property 22: 列表属性继承
*对于任何*列表式文本，所有分割出的待办事项应共享相同的时间和分类。
**Validates: Requirements 10.5**

### Property 23: 无数量品类处理
*对于任何*列表中没有明确数量的品类，Parser_Service 应仍然创建该待办事项。
**Validates: Requirements 10.6**

### Property 24: 提醒标记正确性
*对于任何*包含提醒关键词（"提醒我"、"记得"、"别忘了"）的文本，Parser_Service 应标记该待办事项需要提醒。
**Validates: Requirements 11.1**

### Property 25: 通知调度正确性
*对于任何*设置了提醒的待办事项，当到达提醒时间时，System 应发送本地通知。
**Validates: Requirements 11.6**

### Property 26: 多次提醒调度
*对于任何*设置了多次提醒的待办事项，System 应按照间隔依次调度所有提醒。
**Validates: Requirements 11.7**

### Property 27: 语音创建标记
*对于任何*通过语音创建的待办事项，isVoiceCreated 字段应为 true。
**Validates: Requirements 12.1**

### Property 28: 数据完整性保存
*对于任何*待办事项，保存到数据库时应保存所有字段（标题、描述、分类、优先级、截止日期、提醒配置等）。
**Validates: Requirements 12.2**

### Property 29: 持久化加载正确性
*对于任何*保存到数据库的待办事项，应用重启后应能正确加载。
**Validates: Requirements 12.3**

### Property 30: TodoItem 序列化 Round-Trip
*对于任何*TodoItem 对象，序列化为 JSON 后再反序列化应得到等价的对象（所有字段值相同）。
**Validates: Requirements 12.4, 12.5**

### Property 31: 数据库错误处理
*对于任何*数据库操作失败的场景，System 应记录错误日志并通知用户。
**Validates: Requirements 12.6**

## Implementation Notes

### 依赖包

```yaml
dependencies:
  # 语音识别
  speech_to_text: ^7.0.0
  permission_handler: ^11.0.0
  
  # 本地通知
  flutter_local_notifications: ^18.0.0
  timezone: ^0.9.0
  
  # 数据库
  sqflite: ^2.3.0
  path: ^1.8.3
  
  # 状态管理
  provider: ^6.1.0
  
  # 日期时间
  intl: ^0.19.0
```

### 平台配置

**iOS (ios/Runner/Info.plist)**
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>需要语音识别权限以创建待办事项</string>
<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限以录制语音</string>
```

**Android (android/app/src/main/AndroidManifest.xml)**
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 性能考虑

1. **语音识别**
   - 使用设备本地识别（离线模式）优先
   - 识别超时设置为 60 秒
   - 实时结果更新频率控制在 200ms

2. **解析性能**
   - 关键词匹配使用 HashMap 查找（O(1)）
   - 正则表达式预编译
   - 列表分割限制最大项数（100项）

3. **数据库**
   - 批量插入使用事务
   - 索引优化查询性能
   - 定期清理已完成的旧待办

### 安全考虑

1. **权限管理**
   - 运行时权限请求
   - 权限拒绝后的降级处理
   - 权限状态持久化

2. **数据安全**
   - 本地数据库加密（可选）
   - 敏感信息不记录日志
   - 用户数据不上传云端

### 可访问性

1. **语音反馈**
   - 识别开始/结束的音频提示
   - 错误时的语音提示

2. **视觉反馈**
   - 录音状态的动画指示
   - 高对比度的错误提示
   - 大字体支持

## Future Enhancements

1. **多语言支持**
   - 支持英语、日语等其他语言
   - 自动检测语言

2. **智能学习**
   - 基于用户历史的分类优化
   - 个性化关键词学习

3. **云端同步**
   - 待办事项云端备份
   - 多设备同步

4. **高级解析**
   - 支持更复杂的时间表达式
   - 支持地点信息提取
   - 支持联系人信息提取
