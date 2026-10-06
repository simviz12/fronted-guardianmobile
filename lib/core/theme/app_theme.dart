import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const defaultFont = 'Plus Jakarta Sans';
    final textTheme = const TextTheme().copyWith(
      displayLarge: const TextStyle(
        fontFamily: defaultFont,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.28,
        color: AppColors.textHeadings,
      ),
      headlineMedium: const TextStyle(
        fontFamily: defaultFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: AppColors.textHeadings,
      ),
      headlineSmall: const TextStyle(
        fontFamily: defaultFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        color: AppColors.textHeadings,
      ),
      bodyLarge: const TextStyle(
        fontFamily: defaultFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: AppColors.textBody,
      ),
      bodyMedium: const TextStyle(
        fontFamily: defaultFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: AppColors.textBody,
      ),
      bodySmall: const TextStyle(
        fontFamily: defaultFont,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        color: AppColors.textMuted,
      ),
      labelLarge: const TextStyle(
        fontFamily: defaultFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: AppColors.textHeadings,
      ),
      labelSmall: const TextStyle(
        fontFamily: defaultFont,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.12,
        color: AppColors.textMuted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: Colors.white,
        secondary: Color(0xFF516071),
        onSecondary: Colors.white,
        error: AppColors.alert,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textHeadings,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: const TextStyle(
            fontFamily: defaultFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textHeadings),
        titleTextStyle: TextStyle(
          fontFamily: defaultFont,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textHeadings,
        ),
      ),
    );
  }
}
