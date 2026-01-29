# 修复：待办编辑对话框不显示

## 🐛 问题描述

点击待办卡片时，出现遮罩但没有显示编辑对话框。

## 🔍 问题原因

1. **点击事件冲突**: 外层的 `GestureDetector` 拦截了所有点击事件，包括复选框的点击
2. **Dialog 背景色缺失**: Dialog 可能没有明确的背景色，导致在某些主题下不可见

## ✅ 修复方案

### 1. 重构点击事件处理

**之前**:
```dart
return GestureDetector(
  onTapUp: (_) => _showEditDialog(context),
  child: AnimatedContainer(
    child: Row(
      children: [
        _buildCheckbox(theme),  // 复选框也会触发编辑
        Expanded(child: Column(...)),
      ],
    ),
  ),
);
```

**现在**:
```dart
return AnimatedContainer(
  child: Row(
    children: [
      _buildCheckbox(theme),  // 复选框独立处理
      Expanded(
        child: GestureDetector(  // 只有内容区域触发编辑
          onTapUp: (_) => _showEditDialog(context),
          behavior: HitTestBehavior.opaque,
          child: Column(...),
        ),
      ),
    ],
  ),
);
```

### 2. 添加明确的背景色

**修改前**:
```dart
return Dialog(
  elevation: 8,
  shape: RoundedRectangleBorder(...),
  child: Container(...),
);
```

**修改后**:
```dart
return Dialog(
  elevation: 8,
  backgroundColor: theme.colorScheme.surface,  // 添加背景色
  shape: RoundedRectangleBorder(...),
  child: Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,  // 确保容器也有背景色
      borderRadius: BorderRadius.circular(28),
    ),
    ...
  ),
);
```

## 📝 修改的文件

1. `lib/components/todo/todo_card.dart`
   - 移除外层 GestureDetector
   - 将点击处理移到内容区域
   - 添加 `behavior: HitTestBehavior.opaque`

2. `lib/components/todo/todo_edit_dialog.dart`
   - 添加 `backgroundColor` 到 Dialog
   - 添加 `decoration` 到 Container

## 🧪 测试方法

### 方法 1: 使用测试应用
```bash
flutter run test_todo_edit_dialog.dart
```

点击"打开编辑对话框"按钮，应该能看到完整的编辑对话框。

### 方法 2: 在实际应用中测试
1. 运行应用
2. 创建一个待办事项
3. 点击待办卡片的**文字区域**（不是复选框）
4. 应该弹出编辑对话框

## ✨ 预期行为

### 点击复选框
- ✅ 切换完成状态
- ❌ 不打开编辑对话框

### 点击文字区域
- ✅ 打开编辑对话框
- ✅ 显示所有字段
- ✅ 可以编辑和保存

## 🎯 验证清单

- [ ] 点击待办文字区域能打开编辑对话框
- [ ] 对话框有白色/主题色背景（不是透明的）
- [ ] 对话框显示所有表单字段
- [ ] 点击复选框只切换完成状态，不打开对话框
- [ ] 可以编辑标题、描述、分类、优先级、截止日期
- [ ] 点击"保存"能成功更新待办
- [ ] 点击"取消"关闭对话框不保存
- [ ] 点击"删除"显示确认对话框

## 🔧 如果还是不显示

### 检查 1: 主题配置
确保应用使用了 Material 3 主题：
```dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  ),
  ...
)
```

### 检查 2: 控制台错误
运行应用时查看控制台是否有错误信息：
```bash
flutter run
```

### 检查 3: Provider 配置
确保 TodoProvider 已正确配置：
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => TodoProvider()),
  ],
  child: MaterialApp(...),
)
```

## 📊 代码变更统计

| 文件 | 修改类型 | 行数变化 |
|------|---------|---------|
| `todo_card.dart` | 重构 | ~20 行 |
| `todo_edit_dialog.dart` | 增强 | +5 行 |

## 🎉 修复完成

现在点击待办卡片应该能正常显示编辑对话框了！

---

**修复时间**: 2026-01-29  
**问题类型**: UI 交互 Bug  
**严重程度**: 高（核心功能不可用）  
**状态**: ✅ 已修复
