import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/todo_item.dart';
import '../../providers/todo_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

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

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      onLongPress: () => _showEditDialog(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0, _isPressed ? 2 : 0),
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
              // 内容区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.todo.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: widget.todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: widget.todo.isCompleted
                            ? theme.colorScheme.onSurface.withOpacity(0.5)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (widget.todo.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        widget.todo.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _buildTagsRow(theme),
                  ],
                ),
              ),
            ],
          ),
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
        duration: const Duration(milliseconds: 200),
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
            ? Icon(
                Icons.check,
                size: 18,
                color: AppColors.onPrimary,
              )
            : null,
      ),
    );
  }

  Widget _buildTagsRow(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
    // 编辑待办事项弹窗
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditBottomSheet(todo: widget.todo),
    );
  }
}

/// 编辑待办事项底部弹窗
class _EditBottomSheet extends StatefulWidget {
  final TodoItem todo;

  const _EditBottomSheet({required this.todo});

  @override
  State<_EditBottomSheet> createState() => _EditBottomSheetState();
}

class _EditBottomSheetState extends State<_EditBottomSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController =
        TextEditingController(text: widget.todo.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '编辑待办事项',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '标题',
              hintText: '输入待办事项标题',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: '描述',
              hintText: '输入详细描述（可选）',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _deleteTodo(context),
                  child: const Text('删除'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: () => _saveTodo(context),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  void _saveTodo(BuildContext context) {
    final provider = context.read<TodoProvider>();
    final updatedTodo = widget.todo.copyWith(
      title: _titleController.text,
      description: _descriptionController.text,
    );
    provider.updateTodo(updatedTodo);
    Navigator.pop(context);
  }

  void _deleteTodo(BuildContext context) {
    final provider = context.read<TodoProvider>();
    provider.deleteTodo(widget.todo.id);
    Navigator.pop(context);
  }
}
