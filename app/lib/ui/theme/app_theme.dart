import 'package:flutter/material.dart';

/// Design tokens for ToneStudio UI
class AppColorScheme {
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceElevated;
  final Color cardBackground;
  final Color cardActive;
  final Color headerBackground;
  final Color border;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color accent;
  final Color alert;

  const AppColorScheme({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceElevated,
    required this.cardBackground,
    required this.cardActive,
    required this.headerBackground,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.accent,
    required this.alert,
  });

  bool get isDark => brightness == Brightness.dark;
  Color get sliderInactiveTrack => isDark ? const Color(0x33FFFFFF) : const Color(0xFFCBD5E1);
}

class AppTheme {
  // Legacy constants for backward compatibility
  static const Color darkBackground = Color(0xFF0F0F14);
  static const Color cardBackground = Color(0xFF1A1A22);
  static const Color cardActiveBackground = Color(0xFF22222E);
  static const Color primaryTeal = Color(0xFF00ADB5);
  static const Color accentOrange = Color(0xFFFF5722);
  static const Color alertRed = Color(0xFFE50914);

  // Modern Theme Color Palettes
  static const darkColors = AppColorScheme(
    brightness: Brightness.dark,
    background: Color(0xFF0F0F14),
    surface: Color(0xFF14141E),
    surfaceVariant: Color(0xFF181824),
    surfaceElevated: Color(0xFF1E1E2C),
    cardBackground: Color(0xFF1A1A24),
    cardActive: Color(0xFF222232),
    headerBackground: Color(0xFF161620),
    border: Color(0x33FFFFFF),
    borderSubtle: Color(0x1FFFFFFF),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xB3FFFFFF),
    textMuted: Color(0x8AFFFFFF),
    primary: Color(0xFF00ADB5),
    accent: Color(0xFFFF9800),
    alert: Color(0xFFE50914),
  );

  static const lightColors = AppColorScheme(
    brightness: Brightness.light,
    background: Color(0xFFF1F3F6),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFE8ECF1),
    surfaceElevated: Color(0xFFDEE3E9),
    cardBackground: Color(0xFFFFFFFF),
    cardActive: Color(0xFFE0F7F8),
    headerBackground: Color(0xFFFFFFFF),
    border: Color(0xFFCBD5E1),
    borderSubtle: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
    primary: Color(0xFF00838F),
    accent: Color(0xFFE65100),
    alert: Color(0xFFDC2626),
  );

  /// Resolves active colors based on the current context's theme brightness
  static AppColorScheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkColors : lightColors;
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkColors.background,
      primaryColor: darkColors.primary,
      colorScheme: ColorScheme.dark(
        primary: darkColors.primary,
        secondary: darkColors.accent,
        surface: darkColors.surface,
        onSurface: darkColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkColors.headerBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkColors.textPrimary),
      ),
      cardColor: darkColors.cardBackground,
      dividerColor: darkColors.borderSubtle,
      dialogBackgroundColor: darkColors.surfaceVariant,
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightColors.background,
      primaryColor: lightColors.primary,
      colorScheme: ColorScheme.light(
        primary: lightColors.primary,
        secondary: lightColors.accent,
        surface: lightColors.surface,
        onSurface: lightColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightColors.headerBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: lightColors.textPrimary),
      ),
      cardColor: lightColors.cardBackground,
      dividerColor: lightColors.borderSubtle,
      dialogBackgroundColor: lightColors.surfaceVariant,
      useMaterial3: true,
    );
  }
}
