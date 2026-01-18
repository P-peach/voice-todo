import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// 主题状态管理 Provider
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadThemeMode();
  }

  /// 加载保存的主题模式
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode') ?? 'system';

    switch (savedTheme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        _themeMode = ThemeMode.system;
        break;
    }

    notifyListeners();
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;

    final prefs = await SharedPreferences.getInstance();
    final themeString = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';

    await prefs.setString('theme_mode', themeString);

    notifyListeners();
  }

  /// 切换到浅色模式
  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }

  /// 切换到深色模式
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// 切换到系统模式
  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }
}
