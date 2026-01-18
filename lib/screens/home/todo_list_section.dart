import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/todo_provider.dart';
import '../../theme/app_spacing.dart';
import '../../components/todo/todo_card.dart';

/// 待办事项列表组件
class TodoListSection extends StatelessWidget {
  final bool showOnlyIncomplete;

  const TodoListSection({
    super.key,
    this.showOnlyIncomplete = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TodoProvider>();

    final incompleteTodos = provider.incompleteTodos;
    final completedTodos = provider.completedTodos;
    final isLoading = provider.isLoading;
    final error = provider.error;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '加载失败',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => provider.loadTodos(),
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (incompleteTodos.isEmpty && completedTodos.isEmpty) {
      return _buildEmptyState(theme, true);
    }

    if (showOnlyIncomplete && incompleteTodos.isEmpty) {
      return _buildEmptyState(theme, false);
    }

    return ListView.separated(
      itemCount: showOnlyIncomplete
          ? incompleteTodos.length
          : incompleteTodos.length + completedTodos.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (showOnlyIncomplete) {
          return TodoCard(todo: incompleteTodos[index]);
        } else {
          if (index < incompleteTodos.length) {
            return TodoCard(todo: incompleteTodos[index]);
          } else {
            final completedIndex = index - incompleteTodos.length;
            return Opacity(
              opacity: 0.7,
              child: TodoCard(todo: completedTodos[completedIndex]),
            );
          }
        }
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isAllEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              isAllEmpty ? Icons.checklist : Icons.task_alt,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isAllEmpty ? '暂无待办事项' : '所有待办事项已完成',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isAllEmpty ? '点击麦克风按钮开始语音输入' : '点击下方按钮添加新待办',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
