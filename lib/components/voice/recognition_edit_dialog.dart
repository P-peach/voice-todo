import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// 语音识别后编辑对话框
///
/// 在语音识别完成后，允许用户编辑识别的文本
/// 确认后才会解析并创建待办事项
///
/// 功能：
/// - 显示识别的文本
/// - 允许用户编辑
/// - 确认后回调
/// - 取消后回调
/// - Material 3 BottomSheet 样式
class RecognitionEditDialog extends StatefulWidget {
  /// 识别的文本
  final String recognizedText;

  /// 确认回调（返回编辑后的文本）
  final Function(String) onConfirm;

  /// 取消回调
  final VoidCallback onCancel;

  const RecognitionEditDialog({
    super.key,
    required this.recognizedText,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<RecognitionEditDialog> createState() => _RecognitionEditDialogState();
}

class _RecognitionEditDialogState extends State<RecognitionEditDialog> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.recognizedText);

    // 延迟聚焦，等待对话框动画完成
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _focusNode.requestFocus();
        // 将光标移到文本末尾
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onConfirm(text);
    }
  }

  void _handleCancel() {
    widget.onCancel();
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: mediaQuery.viewInsets.bottom + AppSpacing.lg,
      ),
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

          // 标题
          Row(
            children: [
              Icon(
                Icons.edit_note,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '编辑识别内容',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '确认或修改语音识别的内容',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 文本输入框
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            maxLines: 4,
            minLines: 4,
            decoration: InputDecoration(
              hintText: '输入待办事项内容...',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              counterText: '${_textController.text.length} 字符',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleConfirm(),
            onChanged: (_) {
              // 更新字符计数
              setState(() {});
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // 提示文本
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '支持多个待办，用逗号或"和"分隔',
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
            children: [
              // 取消按钮
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleCancel,
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // 确认按钮
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _handleConfirm,
                  icon: const Icon(Icons.check),
                  label: const Text('确认并创建'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 显示语音识别编辑对话框的辅助方法
Future<String?> showRecognitionEditDialog({
  required BuildContext context,
  required String recognizedText,
}) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return RecognitionEditDialog(
        recognizedText: recognizedText,
        onConfirm: (text) => Navigator.of(context).pop(text),
        onCancel: () => Navigator.of(context).pop(null),
      );
    },
  );
}
