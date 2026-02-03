import 'package:flutter/material.dart';

/// CatchyBus Brand Colors
class AppColors {
  // Primary Colors
  static const Color primaryYellow = Color(
    0xFFF9C300,
  ); // Bus body, brand identity
  static const Color deepBlue = Color(0xFF1E4FA3); // Primary text, headers
  static const Color brightOrange = Color(0xFFF57C00); // Buttons, highlights
  static const Color locationRed = Color(0xFFE53935); // GPS pin, alerts
  static const Color darkCharcoal = Color(0xFF212121); // Body text, icons
  static const Color white = Color(0xFFFFFFFF); // Backgrounds

  // Additional shades for UI variations
  static const Color lightYellow = Color(0xFFFFF9E6);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color lightOrange = Color(0xFFFFE0B2);
}

/// App theme configuration
class AppTheme {
  // Light theme with CatchyBus branding
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryYellow,
        onPrimary: AppColors.darkCharcoal,
        secondary: AppColors.deepBlue,
        onSecondary: AppColors.white,
        tertiary: AppColors.brightOrange,
        error: AppColors.locationRed,
        surface: AppColors.white,
        onSurface: AppColors.darkCharcoal,
      ),
      scaffoldBackgroundColor: AppColors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: AppColors.darkCharcoal,
        iconTheme: IconThemeData(color: AppColors.darkCharcoal),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brightOrange,
          foregroundColor: AppColors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.deepBlue),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightYellow,
        prefixIconColor: AppColors.deepBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.locationRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.locationRed, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.darkCharcoal),
      ),
      iconTheme: const IconThemeData(color: AppColors.darkCharcoal),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.deepBlue,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: AppColors.deepBlue,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: AppColors.deepBlue,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: AppColors.deepBlue,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.deepBlue,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: AppColors.deepBlue,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.deepBlue,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.darkCharcoal,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: AppColors.darkCharcoal,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: AppColors.darkCharcoal),
        bodyMedium: TextStyle(color: AppColors.darkCharcoal),
        bodySmall: TextStyle(color: AppColors.darkCharcoal),
      ),
    );
  }

  // Dark theme with CatchyBus branding
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryYellow,
        onPrimary: AppColors.darkCharcoal,
        secondary: AppColors.deepBlue,
        onSecondary: AppColors.white,
        tertiary: AppColors.brightOrange,
        error: AppColors.locationRed,
        surface: AppColors.darkCharcoal,
        onSurface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.darkCharcoal,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.darkCharcoal,
        foregroundColor: AppColors.primaryYellow,
        iconTheme: IconThemeData(color: AppColors.primaryYellow),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brightOrange,
          foregroundColor: AppColors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primaryYellow),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        prefixIconColor: AppColors.primaryYellow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primaryYellow,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.locationRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.locationRed, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.white),
      ),
      iconTheme: const IconThemeData(color: AppColors.white),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.primaryYellow,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: AppColors.primaryYellow,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: AppColors.primaryYellow,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: AppColors.primaryYellow,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.primaryYellow,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: AppColors.primaryYellow,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: AppColors.white),
        bodyMedium: TextStyle(color: AppColors.white),
        bodySmall: TextStyle(color: AppColors.white),
      ),
    );
  }
}
