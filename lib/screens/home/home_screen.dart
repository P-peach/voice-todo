import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/todo_provider.dart';
import '../../providers/voice_provider.dart';
import '../../services/todo_parser_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'todo_list_section.dart';
import 'add_todo_sheet.dart';

/// 首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceProvider = context.watch<VoiceProvider>();
    final todoProvider = context.watch<TodoProvider>();

    // 设置 context 给 VoiceProvider（用于显示对话框和添加待办）
    voiceProvider.setContext(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VoiceTodo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '手动添加',
            onPressed: () => _showAddTodoSheet(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_completed') {
                _clearCompletedTodos(context);
              } else if (value == 'clear_all') {
                _clearAllTodos(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_completed',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline),
                    SizedBox(width: AppSpacing.sm),
                    Text('清除已完成'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: AppSpacing.sm),
                    Text('清除全部'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 语音输入区域 - 仅显示识别结果
          if (voiceProvider.recognizedText.isNotEmpty && !voiceProvider.isListening)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _buildRecognizedResultCard(context, voiceProvider, todoProvider),
              ),
            ),

          // 完成率统计
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildCompletionRateCard(context, todoProvider),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.md),
          ),

          // 待办事项列表
          SliverFillRemaining(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: const TodoListSection(showOnlyIncomplete: true),
              ),
          ),
        ],
      ),

      // 录音状态指示器
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 录音按钮
          if (!voiceProvider.isListening)
            FloatingActionButton.extended(
              onPressed: () => voiceProvider.startListening(),
              icon: const Icon(Icons.mic),
              label: const Text('录音'),
              heroTag: 'record_btn',
            ),

          // 录音中状态
          if (voiceProvider.isListening)
            FloatingActionButton.extended(
              onPressed: () => voiceProvider.stopListening(),
              icon: const Icon(Icons.stop),
              label: const Text('停止'),
              heroTag: 'record_btn',
              backgroundColor: Theme.of(context).colorScheme.error,
            ),

          const SizedBox(height: AppSpacing.sm),

          // 快速添加按钮
          FloatingActionButton.extended(
            onPressed: () => _showAddTodoSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('添加'),
            heroTag: 'add_btn',
          ),
        ],
      ),
    );
  }

  Widget _buildRecognizedResultCard(
    BuildContext context,
    VoiceProvider voiceProvider,
    TodoProvider todoProvider,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hearing,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '语音识别结果',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            voiceProvider.recognizedText,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addRecognizedTodos(context),
                  icon: const Icon(Icons.check),
                  label: const Text('确认添加'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => voiceProvider.reset(),
                  icon: const Icon(Icons.clear),
                  label: const Text('清除'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRateCard(BuildContext context, TodoProvider provider) {
    final theme = Theme.of(context);
    final incompleteCount = provider.incompleteCount;
    final completedCount = provider.completedCount;
    final totalCount = provider.totalCount;
    final completionRate = provider.completionRate;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '完成率',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(completionRate * 100).toStringAsFixed(0)}',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.xxs,
                          bottom: AppSpacing.sm,
                        ),
                        child: Text(
                          '%',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Circular progress indicator
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: completionRate,
                      strokeWidth: 8,
                      backgroundColor: theme.colorScheme.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.trending_up,
                      color: completionRate > 0.5
                          ? AppColors.success
                          : theme.colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _CompactStatItem(
                label: '已完成',
                value: completedCount,
                color: AppColors.success,
                icon: Icons.check_circle,
              ),
              _CompactStatItem(
                label: '待完成',
                value: incompleteCount,
                color: theme.colorScheme.primary,
                icon: Icons.radio_button_unchecked,
              ),
              _CompactStatItem(
                label: '总计',
                value: totalCount,
                color: theme.colorScheme.tertiary,
                icon: Icons.analytics,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addRecognizedTodos(BuildContext context) async {
    final voiceProvider = context.read<VoiceProvider>();

    if (voiceProvider.recognizedText.isEmpty) return;

    try {
      // 调用 VoiceProvider 的方法来解析并添加待办
      await voiceProvider.parseAndAddTodos();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  void _showAddTodoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddTodoSheet(),
    );
  }

  void _clearCompletedTodos(BuildContext context) {
    final provider = context.read<TodoProvider>();
    final completedIds = provider.completedTodos.map((t) => t.id).toList();
    if (completedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有已完成的待办事项')),
      );
      return;
    }
    provider.deleteTodos(completedIds);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已清除 ${completedIds.length} 个已完成的待办事项')),
    );
  }

  void _clearAllTodos(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有待办事项吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final provider = context.read<TodoProvider>();
              provider.clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清除所有待办事项')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }
}

/// 紧凑统计项组件
class _CompactStatItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _CompactStatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value.toString(),
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

