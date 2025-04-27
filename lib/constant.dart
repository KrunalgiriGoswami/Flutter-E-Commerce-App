import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6200EE); // Vibrant purple
  static const Color primaryVariant = Color(0xFF3700B3); // Darker purple
  static const Color secondary = Color(0xFF03DAC6); // Teal
  static const Color background = Color(0xFFF5F5F5); // Light grey
  static const Color surface = Colors.white; // White for cards
  static const Color textPrimary = Color(0xFF212121); // Dark grey
  static const Color textSecondary = Color(0xFF757575); // Medium grey
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryVariant,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      background: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: TextTheme(
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.surface,
    ),
  );
}
