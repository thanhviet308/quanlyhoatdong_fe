import 'package:flutter/material.dart';

class AppTheme {
  // Palette lấy từ logo
  static const Color primaryGreen = Color(0xFF00703C);
  static const Color secondaryBlue = Color(0xFF2C6FB7);
  static const Color ringCream = Color(0xFFF2E9C7);
  static const Color earthBrown = Color(0xFF8B5E3C);
  static const Color ink = Color(0xFF0F172A);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [secondaryBlue, primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF6F7FB),
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      primary: primaryGreen,
      secondary: secondaryBlue,
      background: const Color(0xFFF6F7FB),
      surface: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: ink, fontWeight: FontWeight.w800),
      headlineSmall: TextStyle(color: ink, fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(color: ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: secondaryBlue, width: 1.6),
      ),
      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: .3,
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      side: const BorderSide(color: primaryGreen),
      fillColor: WidgetStatePropertyAll(primaryGreen),
    ),
  );
}
