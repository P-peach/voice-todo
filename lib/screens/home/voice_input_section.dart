import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_spacing.dart';
import '../../components/voice/microphone_button.dart';
import '../../providers/voice_provider.dart';
import '../../providers/todo_provider.dart';
import '../../services/voice_recognition_service.dart';

/// 语音输入区域组件
class VoiceInputSection extends StatefulWidget {
  const VoiceInputSection({super.key});

  @override
  State<VoiceInputSection> createState() => _VoiceInputSectionState();
}

class _VoiceInputSectionState extends State<VoiceInputSection> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 设置 context 给 VoiceProvider
    final voiceProvider = context.read<VoiceProvider>();
    voiceProvider.setContext(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voiceProvider = context.watch<VoiceProvider>();
    final todoProvider = context.read<TodoProvider>();

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
          // 麦克风按钮（带实时识别文本和错误显示）
          MicrophoneButton(
            isListening: voiceProvider.isListening,
            onPressed: () => _handleMicPressed(context, voiceProvider, todoProvider),
            recognizedText: voiceProvider.isListening ? voiceProvider.recognizedText : null,
            errorMessage: voiceProvider.error,
          ),
          const SizedBox(height: AppSpacing.md),

          // 状态提示
          _buildStatusIndicator(context, voiceProvider),

          // 识别结果预览（识别完成后显示）
          if (voiceProvider.status == VoiceStatus.done && 
              voiceProvider.recognizedText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _buildResultPreview(context, voiceProvider, todoProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, VoiceProvider voiceProvider) {
    final theme = Theme.of(context);
    
    if (voiceProvider.status == VoiceStatus.listening) {
      return Container(
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
      );
    }
    
    if (voiceProvider.status == VoiceStatus.processing) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
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
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '正在处理...',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildResultPreview(
    BuildContext context,
    VoiceProvider voiceProvider,
    TodoProvider todoProvider,
  ) {
    final theme = Theme.of(context);
    
    return Container(
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
            voiceProvider.recognizedText,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _handleConfirm(context, voiceProvider, todoProvider),
                  icon: const Icon(Icons.check),
                  label: const Text('确认添加'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => voiceProvider.reset(),
                icon: const Icon(Icons.clear),
                label: const Text('清除'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleMicPressed(
    BuildContext context,
    VoiceProvider voiceProvider,
    TodoProvider todoProvider,
  ) async {
    if (voiceProvider.isListening) {
      // 停止录音并处理结果
      final todos = await voiceProvider.stopListening();
      
      // 如果解析成功，自动创建待办事项
      if (todos.isNotEmpty) {
        for (final todo in todos) {
          await todoProvider.addTodo(todo);
        }
        
        // 显示成功提示
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('成功创建 ${todos.length} 个待办事项'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        // 重置状态
        voiceProvider.reset();
      }
    } else {
      // 开始录音
      await voiceProvider.startListening();
    }
  }

  Future<void> _handleConfirm(
    BuildContext context,
    VoiceProvider voiceProvider,
    TodoProvider todoProvider,
  ) async {
    // 解析并创建待办事项
    final todos = await voiceProvider.stopListening();
    
    if (todos.isNotEmpty) {
      for (final todo in todos) {
        await todoProvider.addTodo(todo);
      }
      
      // 显示成功提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功创建 ${todos.length} 个待办事项'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // 重置状态
      voiceProvider.reset();
    }
  }
}
