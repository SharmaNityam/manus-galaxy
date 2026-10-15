import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

abstract final class AppTheme {
  static const background = Color(0xFFEAEAEB);
  static const chrome = Color(0xFFEAEAEB);
  static const surface = Color(0xFFFFFFFF);
  static const userMessage = Color(0xFFECECE9);
  static const accent = Color(0xFF171717);
  static const primaryText = Color(0xFF171717);
  static const secondaryText = Color(0xFF777773);

  static final light = ThemeData(
    brightness: Brightness.light,
    fontFamily: defaultTargetPlatform == TargetPlatform.iOS
        ? '.SF Pro Text'
        : 'Inter',
    scaffoldBackgroundColor: background,
    visualDensity: VisualDensity.standard,
    colorScheme: const ColorScheme.light(
      surface: surface,
      primary: accent,
      secondary: accent,
      secondaryContainer: Color(0xFFECECE9),
      onSecondaryContainer: primaryText,
      onPrimary: Colors.white,
      onSurface: primaryText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: chrome,
      foregroundColor: primaryText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      titleTextStyle: TextStyle(
        color: primaryText,
        fontSize: 24,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: primaryText, size: 26),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: primaryText,
      ),
      bodyLarge: TextStyle(fontSize: 17, height: 1.5, color: primaryText),
      bodyMedium: TextStyle(fontSize: 15, height: 1.45, color: primaryText),
      bodySmall: TextStyle(fontSize: 13, height: 1.35, color: secondaryText),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: secondaryText, fontSize: 18),
    ),
    useMaterial3: true,
  );
}
