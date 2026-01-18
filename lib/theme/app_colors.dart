import 'package:flutter/material.dart';

/// 应用颜色常量 - Material 3 配色方案
class AppColors {
  // ==================== 主要色彩 ====================
  static const Color primary = Color(0xFF6750A4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimaryContainer = Color(0xFF21005D);

  // ==================== 次要色彩 ====================
  static const Color secondary = Color(0xFF625B71);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondaryContainer = Color(0xFF1D192B);

  // ==================== 第三色彩 ====================
  static const Color tertiary = Color(0xFF7D5260);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFFD8E4);
  static const Color onTertiaryContainer = Color(0xFF31111D);

  // ==================== 功能色彩 ====================
  // 成功色 (完成勾选)
  static const Color success = Color(0xFF4CAF50);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFD4EACF);

  // 警告色 (提醒到期)
  static const Color warning = Color(0xFFFFA726);
  static const Color onWarning = Color(0xFF000000);
  static const Color warningContainer = Color(0xFFFFE0B2);

  // 错误色
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onErrorContainer = Color(0xFF410E0B);

  // ==================== 背景色 - 浅色模式 ====================
  static const Color lightBackground = Color(0xFFFFFBFE);
  static const Color lightOnBackground = Color(0xFF1C1B1F);
  static const Color lightSurface = Color(0xFFFFFBFE);
  static const Color lightOnSurface = Color(0xFF1C1B1F);
  static const Color lightSurfaceVariant = Color(0xFFE7E0EC);
  static const Color lightOnSurfaceVariant = Color(0xFF49454F);
  static const Color lightOutline = Color(0xFF79747E);
  static const Color lightOutlineVariant = Color(0xFFCAC4D0);
  static const Color lightShadow = Color(0x1A000000);
  static const Color lightScrim = Color(0x1F000000);
  static const Color lightInverseSurface = Color(0xFF313033);
  static const Color lightInverseOnSurface = Color(0xFFF4EFF4);
  static const Color lightInversePrimary = Color(0xFFD0BCFF);

  // ==================== 背景色 - 深色模式 ====================
  static const Color darkBackground = Color(0xFF1C1B1F);
  static const Color darkOnBackground = Color(0xFFE6E1E5);
  static const Color darkSurface = Color(0xFF1C1B1F);
  static const Color darkOnSurface = Color(0xFFE6E1E5);
  static const Color darkSurfaceVariant = Color(0xFF49454F);
  static const Color darkOnSurfaceVariant = Color(0xFFCAC4D0);
  static const Color darkOutline = Color(0xFF938F99);
  static const Color darkOutlineVariant = Color(0xFF49454F);
  static const Color darkShadow = Color(0x33000000);
  static const Color darkScrim = Color(0x33000000);
  static const Color darkInverseSurface = Color(0xFFE6E1E5);
  static const Color darkInverseOnSurface = Color(0xFF313033);
  static const Color darkInversePrimary = Color(0xFF6750A4);

  // ==================== 分类标签颜色 ====================
  static const Map<String, Color> categoryColors = {
    '购物': Color(0xFF4CAF50), // 绿色
    '工作': Color(0xFF2196F3), // 蓝色
    '生活': Color(0xFFFF9800), // 橙色
    '学习': Color(0xFF9C27B0), // 紫色
    '健康': Color(0xFFE91E63), // 粉色
    '其他': Color(0xFF607D8B), // 灰蓝色
  };

  // ==================== 优先级颜色 ====================
  static const Map<String, Color> priorityColors = {
    '高': Color(0xFFB3261E),   // 红色 - 紧急
    '中': Color(0xFFFFA726),   // 橙色 - 一般
    '低': Color(0xFF4CAF50),   // 绿色 - 轻松
  };

  // ==================== 辅助方法 ====================
  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? categoryColors['其他']!;
  }

  static Color getPriorityColor(String priority) {
    return priorityColors[priority] ?? priorityColors['中']!;
  }
}
