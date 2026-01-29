import 'package:flutter/material.dart';

import '../../components/vocabulary/add_vocabulary_entry_dialog.dart';
import '../../models/vocabulary_entry.dart';
import '../../services/custom_vocabulary_service.dart';
import '../../theme/app_spacing.dart';

/// 自定义词汇设置页面
/// 
/// 显示和管理用户的自定义词汇表，用于纠正语音识别错误
/// 
/// 功能：
/// - 显示所有词汇条目列表
/// - 添加新的词汇条目
/// - 删除现有词汇条目
/// - 使用 Material 3 设计风格
class VocabularySettingsScreen extends StatefulWidget {
  const VocabularySettingsScreen({super.key});

  @override
  State<VocabularySettingsScreen> createState() =>
      _VocabularySettingsScreenState();
}

class _VocabularySettingsScreenState extends State<VocabularySettingsScreen> {
  final CustomVocabularyService _vocabularyService =
      CustomVocabularyService.instance;

  List<VocabularyEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  /// 加载词汇条目
  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 确保服务已初始化
      if (!_vocabularyService.isInitialized) {
        await _vocabularyService.initialize();
      }

      final entries = _vocabularyService.getAllEntriesDetailed();

      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载词汇表失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 删除词汇条目
  Future<void> _deleteEntry(String incorrect) async {
    try {
      final success = await _vocabularyService.removeEntry(incorrect);

      if (success) {
        // 重新加载列表
        await _loadEntries();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('词汇条目已删除'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteConfirmation(VocabularyEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除词汇条目 "${entry.incorrect}" → "${entry.correct}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteEntry(entry.incorrect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('自定义词汇'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState(theme)
              : _buildVocabularyList(theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // 显示添加词汇条目对话框
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => const AddVocabularyEntryDialog(),
          );

          // 如果成功添加，重新加载列表
          if (result == true) {
            await _loadEntries();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('词汇条目已添加'),
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('添加词汇'),
      ),
    );
  }

  /// 构建空状态视图
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '暂无自定义词汇',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '点击下方按钮添加常见的语音识别错误词汇及其正确映射',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建词汇列表
  Widget _buildVocabularyList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return _buildVocabularyCard(entry, theme);
      },
    );
  }

  /// 构建单个词汇卡片
  Widget _buildVocabularyCard(VocabularyEntry entry, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: AppSpacing.elevationLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.edit_note,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.incorrect,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.lineThrough,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward,
              size: AppSpacing.iconSmall,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                entry.correct,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        subtitle: entry.usageCount > 0
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  '已使用 ${entry.usageCount} 次',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : null,
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: theme.colorScheme.error,
          ),
          tooltip: '删除',
          onPressed: () => _showDeleteConfirmation(entry),
        ),
      ),
    );
  }
}
