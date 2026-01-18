import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/todo_item.dart';
import '../../models/todo_category.dart';
import '../../providers/todo_provider.dart';
import '../../theme/app_spacing.dart';

/// 添加待办事项底部弹窗
class AddTodoSheet extends StatefulWidget {
  const AddTodoSheet({super.key});

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = '其他';
  String _selectedPriority = '中';
  DateTime? _selectedDeadline;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题栏
            Row(
              children: [
                Text(
                  '添加待办事项',
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 标题输入
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '输入待办事项标题',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入标题';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.sm),

            // 描述输入
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述',
                hintText: '输入详细描述（可选）',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.sm),

            // 分类选择
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '分类',
                prefixIcon: Icon(Icons.category),
              ),
              items: TodoCategory.predefinedCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.name,
                  child: Row(
                    children: [
                      Text(category.icon),
                      const SizedBox(width: AppSpacing.xs),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value ?? '其他';
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // 优先级选择
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: '优先级',
                prefixIcon: Icon(Icons.flag),
              ),
              items: const [
                DropdownMenuItem(value: '高', child: Text('高')),
                DropdownMenuItem(value: '中', child: Text('中')),
                DropdownMenuItem(value: '低', child: Text('低')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value ?? '中';
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // 到期时间选择
            InkWell(
              onTap: _selectDeadline,
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMedium),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '到期时间',
                  prefixIcon: Icon(Icons.schedule),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedDeadline != null
                      ? '${_selectedDeadline!.year}/${_selectedDeadline!.month}/${_selectedDeadline!.day} ${_selectedDeadline!.hour}:${_selectedDeadline!.minute.toString().padLeft(2, '0')}'
                      : '无',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _selectedDeadline != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 按钮
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
                  child: FilledButton(
                    onPressed: _saveTodo,
                    child: const Text('添加'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 1);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate != null && mounted) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
      }
    }
  }

  void _saveTodo() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<TodoProvider>();
    final todo = TodoItem(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      deadline: _selectedDeadline,
      createdAt: DateTime.now(),
      isVoiceCreated: false,
    );

    provider.addTodo(todo);
    Navigator.pop(context);
  }
}
