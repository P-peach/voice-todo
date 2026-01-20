import 'package:flutter/material.dart';
import '../../models/reminder_config.dart';
import '../../theme/app_spacing.dart';

/// 提醒设置对话框
class ReminderDialog extends StatefulWidget {
  final ReminderConfig? initialConfig;
  final Function(ReminderConfig) onConfirm;

  const ReminderDialog({
    super.key,
    this.initialConfig,
    required this.onConfirm,
  });

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  late int _selectedCount;
  late Duration _selectedInterval;

  // 预设的提醒次数选项
  final List<int> _countOptions = [1, 2, 3, 5];
  
  // 预设的提醒间隔选项
  final Map<String, Duration> _intervalOptions = {
    '提前1小时': const Duration(hours: 1),
    '提前3小时': const Duration(hours: 3),
    '提前1天': const Duration(days: 1),
    '提前3天': const Duration(days: 3),
    '提前1周': const Duration(days: 7),
  };

  @override
  void initState() {
    super.initState();
    _selectedCount = widget.initialConfig?.count ?? 1;
    _selectedInterval = widget.initialConfig?.interval ?? const Duration(hours: 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '设置提醒',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 提醒次数选择
            Text(
              '提醒次数',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _countOptions.map((count) {
                final isSelected = _selectedCount == count;
                return ChoiceChip(
                  label: Text('$count次'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCount = count;
                      });
                    }
                  },
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 提醒间隔选择
            Text(
              '提醒间隔',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _intervalOptions.entries.map((entry) {
                final isSelected = _selectedInterval == entry.value;
                return ChoiceChip(
                  label: Text(entry.key),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedInterval = entry.value;
                      });
                    }
                  },
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 提示信息
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '将在截止时间前按设置的间隔发送 $_selectedCount 次提醒',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: _handleConfirm,
                  icon: const Icon(Icons.check),
                  label: const Text('确认'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleConfirm() {
    final config = ReminderConfig(
      count: _selectedCount,
      interval: _selectedInterval,
    );
    widget.onConfirm(config);
    Navigator.of(context).pop();
  }
}
