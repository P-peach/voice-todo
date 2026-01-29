# 待办编辑功能演示

## 功能概述

用户现在可以通过点击待办卡片来编辑待办事项的所有属性。

## 使用流程

### 1. 点击待办卡片

在待办列表中，点击任意待办卡片：

```dart
// lib/components/todo/todo_card.dart
// 点击卡片会触发编辑对话框
TodoCard(todo: myTodo)
```

### 2. 编辑对话框打开

对话框显示所有可编辑字段：

- **标题** (必填) - 最多 100 字符
- **描述** (可选) - 最多 500 字符，3 行
- **分类** - 下拉选择：购物、工作、学习、生活、其他
- **优先级** - 下拉选择：低、中、高（带颜色指示）
- **截止日期** - 日期 + 时间选择器（可清除）

### 3. 表单验证

实时验证确保数据有效：

```dart
// 标题不能为空
if (_titleController.text.trim().isEmpty) {
  setState(() => _titleError = '标题不能为空');
}

// 截止日期不能早于当前时间
if (_selectedDeadline!.isBefore(now)) {
  setState(() => _dateError = '截止日期不能早于当前时间');
}
```

### 4. 保存或取消

- **保存**: 验证通过后更新待办，显示成功提示
- **取消**: 关闭对话框，不保存修改
- **删除**: 显示确认对话框，防止误操作

## 代码示例

### 在任何地方显示编辑对话框

```dart
import 'package:voice_todo/components/todo/todo_edit_dialog.dart';

// 显示编辑对话框
showDialog(
  context: context,
  builder: (context) => TodoEditDialog(todo: myTodo),
);
```

### 使用 Provider 更新待办

```dart
import 'package:provider/provider.dart';
import 'package:voice_todo/providers/todo_provider.dart';

// 更新待办（带验证）
final provider = context.read<TodoProvider>();
final updatedTodo = todo.copyWith(
  title: '新标题',
  priority: '高',
);

try {
  await provider.updateTodoWithValidation(updatedTodo);
  // 成功
} catch (e) {
  // 处理错误
  print('更新失败: $e');
}
```

## UI 截图说明

### 编辑对话框布局

```
┌─────────────────────────────────────┐
│  编辑待办事项                        │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📝 标题 *                    │   │
│  │ [输入框]                     │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📄 描述                      │   │
│  │ [多行输入框]                 │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📁 分类: [工作 ▼]            │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🚩 优先级: [● 高 ▼]          │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📅 截止日期                  │   │
│  │ 2026/2/1 10:00        [×]   │   │
│  └─────────────────────────────┘   │
│                                     │
│  [🗑️ 删除]  [取消]  [💾 保存]     │
└─────────────────────────────────────┘
```

## 验证规则

### 必填字段
- ✅ 标题不能为空
- ✅ 标题最多 100 字符

### 可选字段
- ✅ 描述最多 500 字符
- ✅ 分类必须从预定义列表选择
- ✅ 优先级必须从预定义列表选择
- ✅ 截止日期必须晚于当前时间

### 错误提示
- 标题为空时显示："标题不能为空"
- 日期无效时显示："截止日期不能早于当前时间"
- 错误消息显示在对应字段下方
- 用户输入时自动清除错误

## 用户体验优化

### 自动聚焦
对话框打开时，标题输入框自动获得焦点，用户可以立即开始输入。

### 字符计数
输入框显示剩余字符数，帮助用户控制长度。

### 图标辅助
每个字段都有对应的图标，提高可识别性：
- 📝 标题
- 📄 描述
- 📁 分类
- 🚩 优先级
- 📅 截止日期

### 颜色指示
优先级选择器显示颜色圆点：
- 🔴 高 (红色)
- 🟠 中 (橙色)
- 🟢 低 (绿色)

### 确认删除
删除按钮会显示确认对话框，防止误操作：
```
⚠️ 确认删除
确定要删除这个待办事项吗？此操作无法撤销。
[取消] [删除]
```

## 技术细节

### 状态管理
使用 StatefulWidget 管理表单状态：
- TextEditingController 管理文本输入
- 独立的状态变量管理选择器
- 错误状态独立管理

### Provider 集成
使用 `context.read<TodoProvider>()` 避免不必要的重建：
```dart
final provider = context.read<TodoProvider>();
provider.updateTodoWithValidation(updatedTodo);
```

### 数据持久化
更新流程：
1. 验证表单数据
2. 创建更新后的 TodoItem
3. 调用 Provider.updateTodoWithValidation()
4. Provider 调用 SqliteService.updateTodo()
5. 更新数据库
6. 刷新 UI
7. 显示成功提示

### 错误处理
```dart
try {
  await provider.updateTodoWithValidation(updatedTodo);
  Navigator.pop(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('待办事项已更新')),
  );
} catch (e) {
  // 显示错误提示
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('更新失败: $e')),
  );
}
```

## 测试

### Widget 测试
```bash
flutter test test/components/todo/todo_edit_dialog_test.dart
```

测试覆盖：
- ✅ 显示所有表单字段
- ✅ 初始值正确显示
- ✅ 可以编辑所有字段
- ✅ 验证规则正确执行
- ✅ 按钮功能正常
- ✅ 错误提示正确显示

## 未来改进

可能的增强功能：
- [ ] 添加撤销/重做功能
- [ ] 支持批量编辑
- [ ] 添加更多分类选项
- [ ] 自定义优先级颜色
- [ ] 添加附件支持
- [ ] 添加标签系统
- [ ] 支持重复任务

## 相关文件

- `lib/components/todo/todo_edit_dialog.dart` - 编辑对话框组件
- `lib/components/todo/todo_card.dart` - 待办卡片（触发编辑）
- `lib/providers/todo_provider.dart` - 状态管理和更新逻辑
- `test/components/todo/todo_edit_dialog_test.dart` - 测试文件
- `TASK_6_COMPLETION_SUMMARY.md` - 完成总结
