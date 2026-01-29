import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../models/todo_item.dart';
import '../../providers/todo_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'todo_edit_dialog.dart';

/// 待办事项卡片组件
class TodoCard extends StatefulWidget {
  final TodoItem todo;

  const TodoCard({
    super.key,
    required this.todo,
  });

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: Matrix4.identity()..translateByVector3(Vector3(0, _isPressed ? 2 : 0, 0)),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(
              widget.todo.priority == '高' ? 0.15 : 0.08,
            ),
            blurRadius: widget.todo.priority == '高' ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 自定义复选框
            _buildCheckbox(theme),
            const SizedBox(width: AppSpacing.sm),
            // 内容区域（可点击）
            Expanded(
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  _showEditDialog(context);
                },
                onTapCancel: () => setState(() => _isPressed = false),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                        decoration: widget.todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: widget.todo.isCompleted
                            ? theme.colorScheme.onSurface.withOpacity(0.5)
                            : theme.colorScheme.onSurface,
                      ),
                      child: Text(widget.todo.title),
                    ),
                    if (widget.todo.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: widget.todo.isCompleted ? 0.5 : 1.0,
                        child: Text(
                          widget.todo.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _buildTagsRow(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        final provider = context.read<TodoProvider>();
        if (widget.todo.isCompleted) {
          provider.markAsUncompleted(widget.todo.id);
        } else {
          provider.markAsCompleted(widget.todo.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: widget.todo.isCompleted
              ? theme.colorScheme.primary
              : Colors.transparent,
          border: Border.all(
            color: widget.todo.isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        ),
        child: widget.todo.isCompleted
            ? TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Transform.rotate(
                      angle: value * 0.5,
                      child: Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }

  Widget _buildTagsRow(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 语音创建标记
        if (widget.todo.isVoiceCreated) ...[
          Icon(
            Icons.mic,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        
        // 提醒图标
        if (widget.todo.reminderConfig != null) ...[
          Icon(
            Icons.notifications_active,
            size: 14,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 2),
          Text(
            '${widget.todo.reminderConfig!.count}次',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.tertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        
        // 分类标签
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.getCategoryColor(widget.todo.category)
                .withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Text(
            widget.todo.category,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.getCategoryColor(widget.todo.category),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        // 优先级标签
        if (widget.todo.priority != '中') ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.getPriorityColor(widget.todo.priority)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Text(
              widget.todo.priority,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.getPriorityColor(widget.todo.priority),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        // 到期时间
        if (widget.todo.deadline != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.schedule,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 2),
          Text(
            _formatDeadline(widget.todo.deadline!),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);

    if (deadlineDay == today) {
      return '今天 ${TimeOfDay.fromDateTime(deadline).format(context)}';
    } else if (deadlineDay == today.add(const Duration(days: 1))) {
      return '明天 ${TimeOfDay.fromDateTime(deadline).format(context)}';
    } else {
      return '${deadline.month}/${deadline.day}';
    }
  }

  void _showEditDialog(BuildContext context) {
    // 编辑待办事项底部弹窗
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TodoEditDialog(todo: widget.todo),
    );
  }
}
