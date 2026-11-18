import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkBackground = Color(0xFF101014);
  static const Color cardBackground = Color(0xFF1A1A22);
  static const Color cardActiveBackground = Color(0xFF22222E);
  static const Color primaryTeal = Color(0xFF00ADB5);
  static const Color accentOrange = Color(0xFFFF5722);
  static const Color alertRed = Color(0xFFE50914);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryTeal,
      colorScheme: const ColorScheme.dark(
        primary: primaryTeal,
        secondary: accentOrange,
        surface: cardBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF16161D),
        elevation: 0,
        centerTitle: false,
      ),
      useMaterial3: true,
    );
  }
}
