# 修复重复添加待办事项的问题

## 问题描述
录音结束后点击"确认添加"按钮，偶尔会出现同样的识别内容被添加两次的情况。

## 问题原因

### 1. 状态管理问题
`TodoListSection` 在 `didChangeDependencies` 中使用 `context.watch<TodoProvider>()`，导致每次 Provider 更新时都会触发列表更新逻辑。这可能导致：
- 动画逻辑被多次执行
- 列表项被重复插入

### 2. 缺少防重复机制
`VoiceProvider.parseAndAddTodos()` 方法没有防止重复调用的机制，如果用户快速点击多次"确认添加"按钮，可能会导致重复添加。

### 3. 列表更新逻辑不够健壮
原来的实现在检测列表变化时，没有正确区分"新增"和"更新"的情况，可能导致同一个待办项被多次插入动画列表。

## 解决方案

### 1. 优化 TodoListSection 状态管理

**改进前：**
```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  _updateDisplayedTodos();  // 每次依赖变化都执行
}

void _updateDisplayedTodos() {
  final provider = context.watch<TodoProvider>();  // 会触发重建
  // ...
}
```

**改进后：**
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initializeList();  // 只在初始化时执行一次
  });
}

@override
Widget build(BuildContext context) {
  final provider = context.watch<TodoProvider>();
  _updateDisplayedTodos(provider.incompleteTodos, provider.completedTodos);
  // ...
}
```

### 2. 添加 ID 列表比较机制

```dart
List<String> _previousTodoIds = [];

void _updateDisplayedTodos(
  List<TodoItem> incompleteTodos,
  List<TodoItem> completedTodos,
) {
  final newTodoIds = newTodos.map((t) => t.id).toList();

  // 如果 ID 列表完全相同，只更新内容（例如完成状态变化）
  if (_listEquals(_previousTodoIds, newTodoIds)) {
    setState(() {
      for (int i = 0; i < _displayedTodos.length && i < newTodos.length; i++) {
        _displayedTodos[i] = newTodos[i];
      }
    });
    return;
  }
  
  // 只有在 ID 列表变化时才执行插入/删除动画
  // ...
}
```

### 3. 添加防重复调用机制

**在 VoiceProvider 中：**
```dart
Future<void> parseAndAddTodos() async {
  if (_recognizedText.trim().isEmpty) {
    return;
  }

  // 防止重复调用
  if (_status == VoiceStatus.processing) {
    return;
  }

  try {
    _status = VoiceStatus.processing;
    notifyListeners();
    
    // 解析和添加逻辑...
  } catch (e) {
    // 错误处理...
  }
}
```

### 4. 使用 setState 包裹状态更新

确保所有对 `_displayedTodos` 的修改都在 `setState` 中进行：

```dart
setState(() {
  _displayedTodos.add(newTodo);
});
_listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 400));
```

## 测试验证

修复后需要测试以下场景：

1. ✅ 正常添加单个待办事项
2. ✅ 正常添加多个待办事项
3. ✅ 快速连续点击"确认添加"按钮
4. ✅ 勾选/取消勾选待办事项
5. ✅ 删除待办事项
6. ✅ 录音后立即添加
7. ✅ 录音后等待一段时间再添加

## 技术要点

1. **状态管理分离**：将初始化逻辑放在 `initState`，更新逻辑放在 `build` 中
2. **ID 比较优化**：通过比较 ID 列表判断是否需要执行动画
3. **防重复机制**：使用状态标志防止重复调用
4. **原子性操作**：确保状态更新和动画触发的原子性

## 相关文件

- `lib/screens/home/todo_list_section.dart` - 列表组件优化
- `lib/providers/voice_provider.dart` - 添加防重复机制
