// lib/utils/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primaryColor = Color(0xFF3B82F6);
  
  // Content type colors
  static const Color jokeBackgroundColor = Color(0xFFDBEAFE);
  static const Color jokeTextColor = Color(0xFF1E40AF);
  static const Color bitBackgroundColor = Color(0xFFEDE9FE);
  static const Color bitTextColor = Color(0xFF5B21B6);
  static const Color ideaBackgroundColor = Color(0xFFFEF3C7);
  static const Color ideaTextColor = Color(0xFF92400E);
  
  // Get the theme data
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
      ),
    );
  }
}