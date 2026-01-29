# Dialog 显示问题调试指南

## 🐛 当前问题

点击待办文字后：
- ✅ 显示灰黑色遮罩
- ❌ 没有显示对话框内容
- ❌ 控制台报错：`Assertion failed` in `box.dart` and `shifted_box.dart`

## 🔍 错误分析

### 错误类型
```
Assertion failed: file:///opt/homebrew/share/flutter/packages/flutter/lib/src/rendering/box.dart:2251:12
Assertion failed: file:///opt/homebrew/share/flutter/packages/flutter/lib/src/rendering/shifted_box.dart:354:12
```

这些错误通常表示：
1. **布局约束冲突**: Widget 的尺寸约束不满足
2. **无限尺寸问题**: 某个 Widget 试图占用无限空间
3. **嵌套滚动问题**: ScrollView 嵌套导致的问题

## ✅ 已修复的问题

### 修复 1: 简化 Dialog 布局
**之前**:
```dart
Dialog(
  child: Container(
    constraints: BoxConstraints(maxWidth: 500),
    decoration: BoxDecoration(...),
    child: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Form(...),
      ),
    ),
  ),
)
```

**现在**:
```dart
Dialog(
  backgroundColor: theme.colorScheme.surface,
  child: ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: 500,
      maxHeight: screenHeight * 0.9,  // 添加最大高度
    ),
    child: SingleChildScrollView(
      padding: EdgeInsets.all(24),  // padding 移到 ScrollView
      child: Form(...),
    ),
  ),
)
```

### 修复 2: 移除多余的容器
- 移除了 `Container` 和 `decoration`
- 使用 `Dialog` 的 `backgroundColor` 属性
- 使用 `ConstrainedBox` 替代 `Container`

### 修复 3: 添加高度约束
- 添加 `maxHeight: screenHeight * 0.9`
- 防止对话框超出屏幕

## 🧪 测试步骤

### 步骤 1: 测试简单对话框
```bash
flutter run simple_dialog_test.dart
```

1. 点击"打开简单对话框" - 应该显示白色对话框
2. 点击"打开标准 AlertDialog" - 应该显示标准对话框

如果简单对话框能显示，说明基础布局没问题。

### 步骤 2: 测试实际应用
```bash
flutter run lib/main.dart
```

1. 创建一个待办
2. 点击待办文字区域
3. 观察是否显示对话框

### 步骤 3: 检查控制台
运行时查看控制台是否还有错误：
```
flutter run --verbose
```

## 🔧 进一步调试

### 如果还是不显示

#### 方案 1: 使用 AlertDialog 替代 Dialog
```dart
return AlertDialog(
  title: const Text('编辑待办事项'),
  content: SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 表单字段
      ],
    ),
  ),
  actions: [
    TextButton(...),
    FilledButton(...),
  ],
);
```

#### 方案 2: 使用 showModalBottomSheet
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).viewInsets.bottom,
    ),
    child: SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 表单字段
        ],
      ),
    ),
  ),
);
```

#### 方案 3: 使用全屏对话框
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (context) => Scaffold(
      appBar: AppBar(
        title: const Text('编辑待办事项'),
        actions: [
          TextButton(
            onPressed: _saveTodo,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(...),
      ),
    ),
  ),
);
```

## 📝 检查清单

### 布局检查
- [ ] Dialog 有明确的 `backgroundColor`
- [ ] 有 `maxHeight` 约束
- [ ] `SingleChildScrollView` 的 padding 正确
- [ ] `Column` 使用 `mainAxisSize: MainAxisSize.min`
- [ ] 没有嵌套的 `Container` 和 `decoration`

### 代码检查
- [ ] 所有 import 正确
- [ ] AppSpacing 常量存在
- [ ] Theme 正确配置
- [ ] Provider 正确配置

### 运行时检查
- [ ] 没有控制台错误
- [ ] 遮罩正常显示
- [ ] 对话框内容可见
- [ ] 可以交互

## 🎯 预期结果

### 正常显示
```
┌─────────────────────────────────┐
│  编辑待办事项                    │  ← 标题
│                                 │
│  ┌─────────────────────────┐   │
│  │ 标题 *                  │   │  ← 输入框
│  │ [买大白菜和土豆]         │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 描述                    │   │
│  │ [                    ]  │   │
│  └─────────────────────────┘   │
│                                 │
│  分类: [购物 ▼]                 │
│  优先级: [● 中 ▼]               │
│  截止日期: [选择日期]            │
│                                 │
│  [删除]  [取消]  [保存]         │
└─────────────────────────────┘
```

## 🚨 常见错误

### 错误 1: 无限高度
```
RenderFlex children have non-zero flex but incoming height constraints are unbounded.
```
**解决**: 添加 `maxHeight` 约束

### 错误 2: 布局溢出
```
A RenderFlex overflowed by X pixels on the bottom.
```
**解决**: 使用 `SingleChildScrollView`

### 错误 3: 约束冲突
```
BoxConstraints forces an infinite width/height.
```
**解决**: 使用 `ConstrainedBox` 而不是 `Container`

## 📊 修改历史

| 版本 | 修改 | 状态 |
|------|------|------|
| v1 | 初始实现 | ❌ 不显示 |
| v2 | 添加背景色 | ❌ 不显示 |
| v3 | 简化布局 | ✅ 待测试 |

## 🔄 下一步

1. 运行 `simple_dialog_test.dart` 验证基础布局
2. 如果简单对话框正常，问题在于 TodoEditDialog 的具体实现
3. 如果简单对话框也不显示，问题在于 Flutter 环境或主题配置

---

**调试指南版本**: 1.0  
**最后更新**: 2026-01-29  
**问题状态**: 🔧 调试中
