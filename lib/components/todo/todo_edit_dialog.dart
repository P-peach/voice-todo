import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/todo_item.dart';
import '../../providers/todo_provider.dart';
import '../../theme/app_spacing.dart';

/// 待办事项编辑底部弹窗
class TodoEditDialog extends StatefulWidget {
  final TodoItem todo;

  const TodoEditDialog({
    super.key,
    required this.todo,
  });

  @override
  State<TodoEditDialog> createState() => _TodoEditDialogState();
}

class _TodoEditDialogState extends State<TodoEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late String _selectedPriority;
  DateTime? _selectedDeadline;
  TimeOfDay? _selectedTime;

  String? _titleError;
  String? _dateError;

  final List<String> _categories = ['购物', '工作', '学习', '生活', '其他'];
  final List<String> _priorities = ['低', '中', '高'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController = TextEditingController(text: widget.todo.description);
    _selectedCategory = widget.todo.category;
    _selectedPriority = widget.todo.priority;
    _selectedDeadline = widget.todo.deadline;
    _selectedTime = widget.todo.deadline != null
        ? TimeOfDay.fromDateTime(widget.todo.deadline!)
        : null;

    _titleController.addListener(() {
      if (_titleError != null && _titleController.text.isNotEmpty) {
        setState(() => _titleError = null);
      }
    });
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
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLarge),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: mediaQuery.viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 拖动指示器
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 标题栏
            Row(
              children: [
                Icon(Icons.edit, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '编辑待办事项',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline),
                  color: theme.colorScheme.error,
                  tooltip: '删除',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 标题输入
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '标题 *',
                hintText: '输入待办事项标题',
                errorText: _titleError,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: AppSpacing.md),

            // 描述输入
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述',
                hintText: '输入详细描述（可选）',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: AppSpacing.md),

            // 分类和优先级
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: '分类',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: '优先级',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                    items: _priorities.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: _getPriorityColor(priority),
                            ),
                            const SizedBox(width: 8),
                            Text(priority),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedPriority = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 截止日期
            InkWell(
              onTap: _selectDeadline,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '截止日期',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: _selectedDeadline != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _selectedDeadline = null;
                              _selectedTime = null;
                              _dateError = null;
                            });
                          },
                        )
                      : null,
                  errorText: _dateError,
                ),
                child: Text(
                  _selectedDeadline != null
                      ? _formatDeadline(_selectedDeadline!, _selectedTime)
                      : '选择截止日期（可选）',
                  style: TextStyle(
                    color: _selectedDeadline != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _saveTodo,
                    icon: const Icon(Icons.check),
                    label: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    final initialDate = _selectedDeadline ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDeadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _selectedTime = time;
          _dateError = null;
        });
      }
    }
  }

  String _formatDeadline(DateTime deadline, TimeOfDay? time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);

    String dateStr;
    if (deadlineDay == today) {
      dateStr = '今天';
    } else if (deadlineDay == today.add(const Duration(days: 1))) {
      dateStr = '明天';
    } else {
      dateStr = '${deadline.year}/${deadline.month}/${deadline.day}';
    }

    if (time != null) {
      return '$dateStr ${time.format(context)}';
    }
    return dateStr;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case '高':
        return Colors.red;
      case '中':
        return Colors.orange;
      case '低':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool _validateForm() {
    bool isValid = true;

    if (_titleController.text.trim().isEmpty) {
      setState(() => _titleError = '标题不能为空');
      isValid = false;
    }

    if (_selectedDeadline != null) {
      final now = DateTime.now();
      if (_selectedDeadline!.isBefore(now)) {
        setState(() => _dateError = '截止日期不能早于当前时间');
        isValid = false;
      }
    }

    return isValid;
  }

  void _saveTodo() {
    if (!_validateForm()) {
      return;
    }

    final provider = context.read<TodoProvider>();
    final updatedTodo = widget.todo.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      deadline: _selectedDeadline,
    );

    provider.updateTodoWithValidation(updatedTodo);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('待办事项已更新'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('确认删除'),
        content: const Text('确定要删除这个待办事项吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
              
              final provider = context.read<TodoProvider>();
              provider.deleteTodo(widget.todo.id);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('待办事项已删除'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
