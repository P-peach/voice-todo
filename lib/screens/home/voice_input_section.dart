import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../components/voice/microphone_button.dart';

/// 语音输入区域组件
class VoiceInputSection extends StatelessWidget {
  final bool isListening;
  final String recognizedText;
  final VoidCallback onMicPressed;
  final VoidCallback onConfirm;
  final VoidCallback onClear;

  const VoiceInputSection({
    super.key,
    required this.isListening,
    required this.recognizedText,
    required this.onMicPressed,
    required this.onConfirm,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusExtraLarge),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 麦克风按钮
          MicrophoneButton(
            isListening: isListening,
            onPressed: onMicPressed,
          ),
          const SizedBox(height: AppSpacing.md),

          // 状态提示
          if (isListening)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '正在录音...',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

          // 识别结果预览
          if (recognizedText.isNotEmpty && !isListening) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '识别结果',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    recognizedText,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onConfirm,
                          icon: const Icon(Icons.check),
                          label: const Text('确认添加'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: onClear,
                        icon: const Icon(Icons.clear),
                        label: const Text('清除'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
