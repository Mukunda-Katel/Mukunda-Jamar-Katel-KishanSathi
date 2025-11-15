import 'package:flutter/material.dart';

class AppTheme {
  // Agriculture-themed colors
  static const Color primaryGreen = Color(0xFF2E7D32); // Deep green
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color earthBrown = Color(0xFF795548);
  static const Color skyBlue = Color(0xFF42A5F5);
  static const Color sunYellow = Color(0xFFFFEB3B);
  static const Color wheatGold = Color(0xFFFFD54F);
  static const Color backgroundColor = Color(0xFFF1F8E9);
  static const Color cardColor = Colors.white;
  static const Color errorRed = Color(0xFFD32F2F);

  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: lightGreen,
      surface: cardColor,
      error: errorRed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: lightGreen),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed),
      ),
      prefixIconColor: primaryGreen,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkGreen,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: darkGreen,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.black54,
      ),
    ),
  );
}