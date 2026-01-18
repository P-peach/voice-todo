import 'package:flutter/material.dart';

import '../../models/todo_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// 历史卡片数据模型
class HistoryCardData {
  final String id;
  final String dateLabel;
  final DateTime date;
  final int completedCount;
  final int totalCount;
  final String rate; // "优秀", "良好", "继续"
  final double rateValue; // 0.0 - 1.0

  HistoryCardData({
    required this.id,
    required this.dateLabel,
    required this.date,
    required this.completedCount,
    required this.totalCount,
    required this.rate,
    required this.rateValue,
  });

  factory HistoryCardData.fromTodos(List<TodoItem> todos) {
    if (todos.isEmpty) {
      final now = DateTime.now();
      return HistoryCardData(
        id: now.millisecondsSinceEpoch.toString(),
        dateLabel: _formatDate(now),
        date: now,
        completedCount: 0,
        totalCount: 0,
        rate: '继续',
        rateValue: 0.0,
      );
    }

    // 按日期分组（这里简化为取第一天的数据）
    final firstTodo = todos.first;
    final date = firstTodo.createdAt;
    final dateTodos = todos.where((t) {
      return t.createdAt.year == date.year &&
          t.createdAt.month == date.month &&
          t.createdAt.day == date.day;
    }).toList();

    final completedCount =
        dateTodos.where((t) => t.isCompleted).length;
    final totalCount = dateTodos.length;
    final rateValue = totalCount > 0 ? completedCount / totalCount : 0.0;
    final rate = rateValue >= 0.8 ? '优秀' : (rateValue >= 0.5 ? '良好' : '继续');

    return HistoryCardData(
      id: date.millisecondsSinceEpoch.toString(),
      dateLabel: _formatDate(date),
      date: date,
      completedCount: completedCount,
      totalCount: totalCount,
      rate: rate,
      rateValue: rateValue,
    );
  }

  static String _formatDate(DateTime date) {
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
}

/// 叠放卡片容器组件
class StackedCardContainer extends StatelessWidget {
  final List<HistoryCardData> cards;
  final Function(HistoryCardData) onCardTap;
  final double cardHeight;
  final double maxVisibleCards;

  const StackedCardContainer({
    super.key,
    required this.cards,
    required this.onCardTap,
    this.cardHeight = 120,
    this.maxVisibleCards = 3,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '暂无历史记录',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final visibleCards = cards.take(maxVisibleCards.toInt()).toList();
        final hiddenCount = cards.length - visibleCards.length;

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            // 底部卡片
            ...List.generate(visibleCards.length, (index) {
              final cardIndex = visibleCards.length - 1 - index;
              final data = visibleCards[cardIndex];
              final isTop = index == visibleCards.length - 1;

              return Positioned(
                top: index * (cardHeight * 0.3),
                child: _buildStackedCard(
                  context,
                  data,
                  index,
                  isTop,
                  cardHeight,
                ),
              );
            }),

            // 隐藏卡片数量提示
            if (hiddenCount > 0)
              Positioned(
                top: (visibleCards.length - 1) * (cardHeight * 0.3) +
                    cardHeight,
                child: _buildMoreIndicator(context, hiddenCount),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStackedCard(
    BuildContext context,
    HistoryCardData data,
    int stackIndex,
    bool isTop,
    double cardHeight,
  ) {
    final theme = Theme.of(context);
    final scale = 1.0 - (stackIndex * 0.08);
    final opacity = 1.0 - (stackIndex * 0.2);

    return GestureDetector(
      onTap: () {
        if (isTop) {
          onCardTap(data);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        width: 280,
        height: cardHeight,
        transform: Matrix4.identity()..translate(0, -stackIndex * 8.0),
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surfaceVariant,
                    theme.colorScheme.surface,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isTop
                      ? theme.colorScheme.primary.withOpacity(0.3)
                      : theme.colorScheme.outlineVariant.withOpacity(0.5),
                  width: isTop ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          data.dateLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isTop
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        _buildCompletionBadge(theme, data),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${data.completedCount}/${data.totalCount} 完成',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                     ),
                     if (data.totalCount > 0) ...[
                       const SizedBox(height: AppSpacing.xs),
                       LinearProgressIndicator(
                         value: data.rateValue,
                         backgroundColor: theme.colorScheme.surfaceVariant,
                         valueColor: AlwaysStoppedAnimation<Color>(
                           theme.colorScheme.primary,
                         ),
                         minHeight: 4,
                         borderRadius: BorderRadius.circular(2),
                       ),
                     ],
                   ],
                 ),
               ),
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildCompletionBadge(ThemeData theme, HistoryCardData data) {
    final rateValue = data.rateValue;
    Color badgeColor;
    String badgeText;

    if (rateValue >= 0.8) {
      badgeColor = AppColors.success;
      badgeText = '优秀';
    } else if (rateValue >= 0.5) {
      badgeColor = AppColors.warning;
      badgeText = '良好';
    } else {
      badgeColor = theme.colorScheme.onSurfaceVariant;
      badgeText = '继续';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        badgeText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMoreIndicator(BuildContext context, int count) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showFullHistory(context),
      child: Container(
        width: 280,
        height: 60,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            style: BorderStyle.solid,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '还有 $count 天记录',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _showFullHistory(BuildContext context) {
    // 显示完整历史记录列表
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullHistoryScreen(cards: cards),
      ),
    );
  }
}

/// 完整历史记录页面
class _FullHistoryScreen extends StatelessWidget {
  final List<HistoryCardData> cards;

  const _FullHistoryScreen({required this.cards});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('完整历史'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: cards.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final data = cards[index];
          return _buildHistoryCard(context, data, theme);
        },
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    HistoryCardData data,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          // 日期
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.dateLabel,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${data.completedCount}/${data.totalCount} 完成',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // 进度条
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              value: data.rateValue,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // 评价
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Text(
              data.rate,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
