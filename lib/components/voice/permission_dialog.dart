import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_spacing.dart';

/// 权限请求对话框
/// 
/// 显示权限说明并提供跳转到设置的功能
class PermissionDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isPermanentlyDenied;

  const PermissionDialog({
    super.key,
    required this.title,
    required this.message,
    this.isPermanentlyDenied = false,
  });

  /// 显示麦克风权限请求对话框
  static Future<bool?> showMicrophonePermission(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PermissionDialog(
        title: '需要麦克风权限',
        message: '语音输入功能需要访问您的麦克风。\n\n'
            '我们会使用麦克风录制您的语音，并将其转换为文字，帮助您快速创建待办事项。\n\n'
            '您的语音数据仅在本地处理，不会上传到服务器。',
        isPermanentlyDenied: false,
      ),
    );
  }

  /// 显示语音识别权限请求对话框
  static Future<bool?> showSpeechPermission(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PermissionDialog(
        title: '需要语音识别权限',
        message: '语音输入功能需要使用系统的语音识别服务。\n\n'
            '我们会使用系统原生的语音识别功能将您的语音转换为文字。\n\n'
            '您的语音数据由系统处理，应用不会保存或上传您的语音。',
        isPermanentlyDenied: false,
      ),
    );
  }

  /// 显示权限被永久拒绝的对话框
  static Future<bool?> showPermanentlyDenied(
    BuildContext context, {
    required String permissionName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionDialog(
        title: '权限已被拒绝',
        message: '您已拒绝了$permissionName权限。\n\n'
            '要使用语音输入功能，请在系统设置中手动开启权限。',
        isPermanentlyDenied: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      title: Row(
        children: [
          Icon(
            isPermanentlyDenied ? Icons.warning_rounded : Icons.mic_rounded,
            color: isPermanentlyDenied
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
            if (isPermanentlyDenied) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '点击"前往设置"按钮，在系统设置中找到本应用，然后开启相应权限。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!isPermanentlyDenied) ...[
          // 普通权限请求：取消和允许按钮
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '取消',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check, size: 20),
            label: const Text('允许'),
          ),
        ] else ...[
          // 永久拒绝：取消和前往设置按钮
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '取消',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () async {
              // 打开应用设置页面
              await openAppSettings();
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            icon: const Icon(Icons.settings, size: 20),
            label: const Text('前往设置'),
          ),
        ],
      ],
    );
  }
}

