import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFF111111);
  static const surface = Color(0xFF222222);
  static const accent = Color(0xFF75A9FF);

  static final dark = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      surface: surface,
      primary: accent,
      onPrimary: Color(0xFF101010),
      onSurface: Color(0xFFF3F3F3),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      bodyLarge: TextStyle(fontSize: 17, height: 1.5),
      bodyMedium: TextStyle(fontSize: 15, height: 1.45),
    ),
    useMaterial3: true,
  );
}
