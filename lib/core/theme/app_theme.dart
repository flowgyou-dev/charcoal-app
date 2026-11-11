import 'package:flutter/material.dart';

class AppTheme {
  // Charcoal System Hybrid Color Palette
  static const Color headerForest = Color(0xFF243D3C);
  static const Color sidebarTeal = Color(0xFF293E3E);
  static const Color hoverSlate = Color(0xFF344E4D);
  static const Color canvasMist = Color(0xFFF3F5F4);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color surfaceBorder = Color(0xFFDCE2E0);
  static const Color inkCharcoal = Color(0xFF1E2929);
  static const Color mutedSlate = Color(0xFF617070);
  static const Color emeraldGreen = Color(0xFF3E7C59);
  static const Color sageWatermark = Color(0xFFD5DDD9);
  static const Color warningAmber = Color(0xFFB45309);

  // Semantic aliases for compatibility across feature screens
  static const Color primaryAmber = headerForest;
  static const Color darkBg = canvasMist;
  static const Color cardBg = cardWhite;

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: canvasMist,
      primaryColor: headerForest,
      colorScheme: const ColorScheme.light(
        primary: headerForest,
        secondary: emeraldGreen,
        surface: cardWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: inkCharcoal,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: headerForest,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceBorder),
        ),
        elevation: 1.5,
        shadowColor: Colors.black12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: headerForest,
          foregroundColor: Colors.white,
          disabledBackgroundColor: sageWatermark,
          disabledForegroundColor: mutedSlate,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: headerForest,
          minimumSize: const Size(64, 46),
          side: const BorderSide(color: surfaceBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardWhite,
        prefixIconColor: mutedSlate,
        suffixIconColor: mutedSlate,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: headerForest, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.8),
        ),
        labelStyle: const TextStyle(color: mutedSlate, fontSize: 13),
        hintStyle: const TextStyle(color: mutedSlate, fontSize: 13),
        errorStyle: TextStyle(color: Colors.red.shade700, fontSize: 11),
      ),
    );
  }
}
