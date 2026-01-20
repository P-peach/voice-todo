# 待办事项动画功能

## 新增动画效果

### 1. 勾选动画 ✓
当用户勾选待办事项时，复选框会展示优雅的动画效果：
- **缩放动画**：勾选标记从 0 到 1 的弹性缩放效果
- **旋转动画**：轻微的旋转效果（0.5 弧度）
- **弹性曲线**：使用 `Curves.elasticOut` 实现自然的弹跳效果
- **时长**：400ms，提供流畅的视觉反馈

```dart
TweenAnimationBuilder<double>(
  duration: const Duration(milliseconds: 400),
  curve: Curves.elasticOut,
  tween: Tween(begin: 0.0, end: 1.0),
  builder: (context, value, child) {
    return Transform.scale(
      scale: value,
      child: Transform.rotate(
        angle: value * 0.5,
        child: Icon(Icons.check, ...),
      ),
    );
  },
)
```

### 2. 文本状态动画
完成状态的文本会平滑过渡：
- **删除线动画**：标题文本的删除线效果平滑出现
- **透明度动画**：文本和描述的透明度渐变到 50%
- **颜色过渡**：文本颜色平滑过渡
- **时长**：300ms

```dart
AnimatedDefaultTextStyle(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  style: TextStyle(
    decoration: isCompleted ? TextDecoration.lineThrough : null,
    color: isCompleted ? color.withOpacity(0.5) : color,
  ),
  child: Text(title),
)
```

### 3. 删除动画
删除待办事项时的流畅过渡：
- **滑出动画**：卡片向右滑出屏幕
- **淡出动画**：同时透明度降低到 0
- **确认对话框**：删除前显示确认对话框，防止误操作
- **时长**：400ms

```dart
SlideTransition(
  position: animation.drive(
    Tween<Offset>(
      begin: const Offset(1, 0),  // 向右滑出
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeInOut)),
  ),
  child: FadeTransition(
    opacity: animation,
    child: TodoCard(...),
  ),
)
```

### 4. 列表项动画
使用 `AnimatedList` 实现智能的列表动画：
- **新增动画**：新待办从左侧滑入
- **删除动画**：已删除项向右滑出
- **自动检测**：自动检测列表变化并应用相应动画
- **平滑过渡**：所有列表项位置变化都有平滑过渡

## 动画参数

| 动画类型 | 时长 | 曲线 | 效果 |
|---------|------|------|------|
| 勾选标记 | 400ms | elasticOut | 弹性缩放 + 旋转 |
| 文本状态 | 300ms | easeInOut | 删除线 + 透明度 |
| 删除过渡 | 400ms | easeInOut | 滑出 + 淡出 |
| 复选框背景 | 300ms | easeInOut | 颜色 + 边框 |

## 用户体验改进

1. **视觉反馈**：每个操作都有清晰的视觉反馈
2. **流畅性**：所有动画使用合适的时长和曲线，避免生硬
3. **优雅性**：弹性动画和渐变效果提升品质感
4. **防误操作**：删除前显示确认对话框
5. **性能优化**：使用 Flutter 内置动画组件，性能优异

## 技术实现

- 使用 `AnimatedContainer` 实现复选框背景动画
- 使用 `TweenAnimationBuilder` 实现勾选标记的自定义动画
- 使用 `AnimatedDefaultTextStyle` 实现文本样式动画
- 使用 `AnimatedOpacity` 实现透明度动画
- 使用 `AnimatedList` 实现列表项的增删动画
- 使用 `SlideTransition` 和 `FadeTransition` 实现删除过渡
