import 'package:flutter/material.dart';

import '../../services/custom_vocabulary_service.dart';
import '../../theme/app_spacing.dart';

/// 添加自定义词汇条目对话框
///
/// 允许用户添加新的词汇映射，用于纠正语音识别错误
///
/// 功能：
/// - 输入错误识别的词汇
/// - 输入正确的词汇
/// - 验证非空字段
/// - 保存到 CustomVocabularyService
/// - Material 3 Dialog 样式
class AddVocabularyEntryDialog extends StatefulWidget {
  const AddVocabularyEntryDialog({super.key});

  @override
  State<AddVocabularyEntryDialog> createState() =>
      _AddVocabularyEntryDialogState();
}

class _AddVocabularyEntryDialogState extends State<AddVocabularyEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _incorrectController = TextEditingController();
  final _correctController = TextEditingController();
  final CustomVocabularyService _vocabularyService =
      CustomVocabularyService.instance;

  bool _isSaving = false;
  String? _incorrectError;
  String? _correctError;

  @override
  void dispose() {
    _incorrectController.dispose();
    _correctController.dispose();
    super.dispose();
  }

  /// 验证输入字段
  bool _validateFields() {
    setState(() {
      _incorrectError = null;
      _correctError = null;
    });

    bool isValid = true;

    // 验证错误词汇字段
    if (_incorrectController.text.trim().isEmpty) {
      setState(() {
        _incorrectError = '请输入错误识别的词汇';
      });
      isValid = false;
    }

    // 验证正确词汇字段
    if (_correctController.text.trim().isEmpty) {
      setState(() {
        _correctError = '请输入正确的词汇';
      });
      isValid = false;
    }

    return isValid;
  }

  /// 保存词汇条目
  Future<void> _saveEntry() async {
    if (!_validateFields()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _vocabularyService.addEntry(
        _incorrectController.text.trim(),
        _correctController.text.trim(),
      );

      if (mounted) {
        // 返回 true 表示成功添加
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusExtraLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题
              Text(
                '添加词汇条目',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '添加常见的语音识别错误及其正确映射',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 错误词汇输入框
              TextField(
                controller: _incorrectController,
                decoration: InputDecoration(
                  labelText: '错误识别的词汇',
                  hintText: '例如：白菜',
                  errorText: _incorrectError,
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                  ),
                ),
                textInputAction: TextInputAction.next,
                enabled: !_isSaving,
                onChanged: (_) {
                  // 清除错误提示
                  if (_incorrectError != null) {
                    setState(() {
                      _incorrectError = null;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // 正确词汇输入框
              TextField(
                controller: _correctController,
                decoration: InputDecoration(
                  labelText: '正确的词汇',
                  hintText: '例如：大白菜',
                  errorText: _correctError,
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(
                    Icons.check_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                ),
                textInputAction: TextInputAction.done,
                enabled: !_isSaving,
                onChanged: (_) {
                  // 清除错误提示
                  if (_correctError != null) {
                    setState(() {
                      _correctError = null;
                    });
                  }
                },
                onSubmitted: (_) {
                  if (!_isSaving) {
                    _saveEntry();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 取消按钮
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // 保存按钮
                  FilledButton(
                    onPressed: _isSaving ? null : _saveEntry,
                    child: _isSaving
                        ? SizedBox(
                            width: AppSpacing.iconStandard,
                            height: AppSpacing.iconStandard,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
