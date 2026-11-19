import 'package:flutter/material.dart';

enum AppThemeMode {
  dark,
  light,
  system,
}

/// Service managing ToneStudio's visual appearance and theme mode.
class ThemeService extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.dark;

  AppThemeMode get mode => _mode;

  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  bool get isDarkMode => _mode == AppThemeMode.dark;
  bool get isLightMode => _mode == AppThemeMode.light;
  bool get isSystemMode => _mode == AppThemeMode.system;

  void setThemeMode(AppThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_mode == AppThemeMode.dark) {
      setThemeMode(AppThemeMode.light);
    } else {
      setThemeMode(AppThemeMode.dark);
    }
  }
}
