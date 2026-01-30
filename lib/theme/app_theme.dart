import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// 应用主题配置 - Material 3
class AppTheme {
  // ==================== 浅色主题 ====================
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      outline: AppColors.lightOutline,
      outlineVariant: AppColors.lightOutlineVariant,
      background: AppColors.lightBackground,
      onBackground: AppColors.lightOnBackground,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightOnSurface,
      surfaceVariant: AppColors.lightSurfaceVariant,
      onSurfaceVariant: AppColors.lightOnSurfaceVariant,
      inverseSurface: AppColors.lightInverseSurface,
      onInverseSurface: AppColors.lightInverseOnSurface,
      inversePrimary: AppColors.lightInversePrimary,
      shadow: AppColors.lightShadow,
      scrim: AppColors.lightScrim,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: _buildAppBarTheme(colorScheme),
      cardTheme: _buildCardTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(colorScheme),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(colorScheme),
      checkboxTheme: _buildCheckboxTheme(colorScheme),
      progressIndicatorTheme: _buildProgressIndicatorTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),
    );
  }

  // ==================== 深色主题 (温暖橘色系) ====================
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary, // 珊瑚橘
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: AppColors.darkPrimaryContainer, // 深橘棕
      onPrimaryContainer: AppColors.darkOnPrimaryContainer,
      secondary: AppColors.darkSecondary, // 琥珀金
      onSecondary: AppColors.darkOnSecondary,
      secondaryContainer: AppColors.darkSecondaryContainer, // 深棕
      onSecondaryContainer: AppColors.darkOnSecondaryContainer,
      tertiary: AppColors.darkTertiary, // 暖粉橘
      onTertiary: AppColors.darkOnTertiary,
      tertiaryContainer: AppColors.darkTertiaryContainer,
      onTertiaryContainer: AppColors.darkOnTertiaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      background: AppColors.darkBackground,
      onBackground: AppColors.darkOnBackground,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      surfaceVariant: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      inverseSurface: AppColors.darkInverseSurface,
      onInverseSurface: AppColors.darkInverseOnSurface,
      inversePrimary: AppColors.darkInversePrimary,
      shadow: AppColors.darkShadow,
      scrim: AppColors.darkScrim,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      textTheme: _buildTextTheme(colorScheme),
      appBarTheme: _buildAppBarTheme(colorScheme),
      cardTheme: _buildCardTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      inputDecorationTheme: _buildInputDecorationTheme(colorScheme),
      chipTheme: _buildChipTheme(colorScheme),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(colorScheme),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(colorScheme),
      checkboxTheme: _buildCheckboxTheme(colorScheme),
      progressIndicatorTheme: _buildProgressIndicatorTheme(colorScheme),
      snackBarTheme: _buildSnackBarTheme(colorScheme),
      dialogTheme: _buildDialogTheme(colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(colorScheme),
    );
  }

  // ==================== 主题组件配置 ====================
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      displaySmall: AppTypography.displaySmall,
      headlineLarge: AppTypography.headlineLarge,
      headlineMedium: AppTypography.headlineMedium,
      headlineSmall: AppTypography.headlineSmall,
      titleLarge: AppTypography.titleLarge,
      titleMedium: AppTypography.titleMedium,
      titleSmall: AppTypography.titleSmall,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    );
  }

  static AppBarTheme _buildAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      elevation: AppSpacing.elevationLow,
      centerTitle: true,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: AppSpacing.iconStandard,
      ),
      titleTextStyle: AppTypography.titleLarge,
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      elevation: AppSpacing.elevationMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      clipBehavior: Clip.antiAlias,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: AppSpacing.elevationLow,
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeightStandard),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(ColorScheme colorScheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeightStandard),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.buttonHeightStandard),
        side: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  static ChipThemeData _buildChipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceVariant,
      deleteIconColor: colorScheme.onSurfaceVariant,
      disabledColor: colorScheme.surfaceVariant.withOpacity(0.38),
      selectedColor: colorScheme.primaryContainer,
      secondarySelectedColor: colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      labelStyle: AppTypography.labelMedium,
      secondaryLabelStyle: AppTypography.labelMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme(ColorScheme colorScheme) {
    return BottomNavigationBarThemeData(
      elevation: AppSpacing.elevationMedium,
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      selectedLabelStyle: AppTypography.labelSmall,
      unselectedLabelStyle: AppTypography.labelSmall,
      showUnselectedLabels: true,
    );
  }

  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme(ColorScheme colorScheme) {
    return FloatingActionButtonThemeData(
      elevation: AppSpacing.elevationHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusExtraLarge),
      ),
    );
  }

  static CheckboxThemeData _buildCheckboxTheme(ColorScheme colorScheme) {
    return CheckboxThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  static ProgressIndicatorThemeData _buildProgressIndicatorTheme(ColorScheme colorScheme) {
    return ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.surfaceVariant,
    );
  }

  static SnackBarThemeData _buildSnackBarTheme(ColorScheme colorScheme) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      elevation: AppSpacing.elevationHigh,
    );
  }

  static DialogThemeData _buildDialogTheme(ColorScheme colorScheme) {
    return DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      elevation: AppSpacing.elevationExtraHigh,
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme(ColorScheme colorScheme) {
    return BottomSheetThemeData(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusExtraLarge),
        ),
      ),
      elevation: AppSpacing.elevationExtraHigh,
    );
  }
}
