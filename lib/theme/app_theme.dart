import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFFF6F61);
  static const Color secondary = Color(0xFFFFB3A7);
  static const Color background = Color(0xFFFFF7F4);
  static const Color card = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      fontFamily: 'Rubik',

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}