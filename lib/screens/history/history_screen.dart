import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/todo_item.dart';
import '../../providers/todo_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// 历史记录页面 - 时间线视图
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<TodoProvider>();
    final completedTodos = provider.completedTodos;

    // 按日期分组
    final groupedTodos = _groupTodosByDate(completedTodos);

    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadTodos(),
            tooltip: '刷新',
          ),
        ],
      ),
      body: groupedTodos.isEmpty
          ? _buildEmptyState(context, theme)
          : _buildTimeline(context, theme, groupedTodos),
    );
  }

  /// 构建时间线视图
  Widget _buildTimeline(
    BuildContext context,
    ThemeData theme,
    Map<DateTime, List<TodoItem>> groupedTodos,
  ) {
    final sortedDates = groupedTodos.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 新的在前

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final todos = groupedTodos[date]!;
        final isLast = index == sortedDates.length - 1;

        return _TimelineDayCard(
          date: date,
          todos: todos,
          isLast: isLast,
          onTap: () => _showDayDetail(context, date, todos),
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '暂无历史记录',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '完成的待办事项将显示在这里',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 按日期分组待办事项
  Map<DateTime, List<TodoItem>> _groupTodosByDate(List<TodoItem> todos) {
    final Map<DateTime, List<TodoItem>> grouped = {};

    for (final todo in todos) {
      final date = DateTime(
        todo.createdAt.year,
        todo.createdAt.month,
        todo.createdAt.day,
      );

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(todo);
    }

    return grouped;
  }

  /// 显示日期详情弹窗
  void _showDayDetail(BuildContext context, DateTime date, List<TodoItem> todos) {
    final theme = Theme.of(context);
    final completedCount = todos.length;
    final formattedDate = _formatDate(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusExtraLarge),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '完成了 $completedCount 个待办事项',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Todo list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                itemCount: todos.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  return _TodoDetailItem(todo: todos[index]);
                },
              ),
            ),
            // Close button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSpacing.buttonHeightStandard),
                ),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return '今天';
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      return '昨天';
    } else {
      return '${date.year}年${date.month}月${date.day}日';
    }
  }
}

/// 时间线日期卡片
class _TimelineDayCard extends StatelessWidget {
  final DateTime date;
  final List<TodoItem> todos;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineDayCard({
    required this.date,
    required this.todos,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMultiple = todos.length > 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 时间线左侧
        SizedBox(
          width: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _getDayLabel(date),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                _getMonthLabel(date),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // 时间线中间
        SizedBox(
          width: 30,
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    height: double.infinity,
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
        ),
        // 时间线右侧 - 卡片
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surfaceContainerHighest,
                    theme.colorScheme.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: hasMultiple
                    ? _buildStackedCardsPreview(context, theme, todos)
                    : _buildSingleCardPreview(context, theme, todos.first),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建堆叠卡片预览
  Widget _buildStackedCardsPreview(
    BuildContext context,
    ThemeData theme,
    List<TodoItem> todos,
  ) {
    final dateLabelText = _formatDateLabel(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateLabelText,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Text(
                '${todos.length} 项',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // 显示前3个待办项作为预览
        ...todos.take(3).toList().asMap().entries.map((entry) {
          final index = entry.key;
          final todo = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? 0 : AppSpacing.xs,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      todo.title,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        if (todos.length > 3) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '还有 ${todos.length - 3} 项...',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  /// 构建单个卡片预览
  Widget _buildSingleCardPreview(
    BuildContext context,
    ThemeData theme,
    TodoItem todo,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: const Icon(
            Icons.check,
            color: AppColors.success,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                todo.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (todo.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  todo.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  /// 格式化日期标签
  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return '今天';
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      return '昨天';
    } else {
      return '${date.month}月${date.day}日';
    }
  }

  /// 获取星期几
  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return '今天';
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      return '昨天';
    }

    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[date.weekday - 1];
  }

  /// 获取月份标签
  String _getMonthLabel(DateTime date) {
    return '${date.month}月${date.day}日';
  }
}

/// 待办事项详情项
class _TodoDetailItem extends StatelessWidget {
  final TodoItem todo;

  const _TodoDetailItem({required this.todo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                if (todo.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    todo.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.getCategoryColor(todo.category)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: Text(
                        todo.category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.getCategoryColor(todo.category),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (todo.priority != '中')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getPriorityColor(todo.priority)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                        ),
                        child: Text(
                          todo.priority,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.getPriorityColor(todo.priority),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '完成于 ${_formatCompletedAt(todo.completedAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompletedAt(DateTime? completedAt) {
    if (completedAt == null) return '';
    return '${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')}';
  }
}
