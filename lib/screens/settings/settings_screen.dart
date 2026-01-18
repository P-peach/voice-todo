import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../theme/app_spacing.dart';

/// 设置页面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildSection(
            context,
            title: '外观',
            children: [
              _ThemeModeSelector(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSection(
            context,
            title: '关于',
            children: [
              _AboutTile(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// 主题模式选择器
class _ThemeModeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ThemeProvider>();

    return Column(
      children: [
        _ThemeModeTile(
          title: '浅色模式',
          subtitle: '使用浅色主题',
          icon: Icons.light_mode,
          isSelected: provider.themeMode == ThemeMode.light,
          onTap: () => provider.setLightMode(),
        ),
        Divider(
          height: 1,
          thickness: 1,
          indent: AppSpacing.xl,
          endIndent: AppSpacing.md,
          color: theme.colorScheme.outlineVariant,
        ),
        _ThemeModeTile(
          title: '深色模式',
          subtitle: '使用深色主题',
          icon: Icons.dark_mode,
          isSelected: provider.themeMode == ThemeMode.dark,
          onTap: () => provider.setDarkMode(),
        ),
        Divider(
          height: 1,
          thickness: 1,
          indent: AppSpacing.xl,
          endIndent: AppSpacing.md,
          color: theme.colorScheme.outlineVariant,
        ),
        _ThemeModeTile(
          title: '跟随系统',
          subtitle: '根据系统设置自动切换',
          icon: Icons.brightness_auto,
          isSelected: provider.themeMode == ThemeMode.system,
          onTap: () => provider.setSystemMode(),
        ),
      ],
    );
  }
}

/// 主题模式选项
class _ThemeModeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : null,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}

/// 关于应用信息
class _AboutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(
        'VoiceTodo',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '版本 1.0.0\n智能语音待办清单应用',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
