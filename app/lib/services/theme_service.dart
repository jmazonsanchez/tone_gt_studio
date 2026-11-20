import 'package:flutter/material.dart';
import 'storage/app_database.dart';

enum AppThemeMode {
  dark,
  light,
  system,
}

/// Service managing ToneStudio's visual appearance and theme mode.
/// Automatically persists user preference in AppDatabase.
class ThemeService extends ChangeNotifier {
  final AppDatabase? _database;
  AppThemeMode _mode = AppThemeMode.dark;

  ThemeService({AppDatabase? database}) : _database = database ?? AppDatabase.instance {
    _loadFromDatabase();
  }

  void _loadFromDatabase() {
    final saved = _database?.getThemeMode();
    if (saved == 'light') {
      _mode = AppThemeMode.light;
    } else if (saved == 'system') {
      _mode = AppThemeMode.system;
    } else {
      _mode = AppThemeMode.dark;
    }
  }

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
    _database?.saveThemeMode(mode.name);
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
