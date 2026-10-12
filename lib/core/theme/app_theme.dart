import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static const defaultFont = 'Plus Jakarta Sans';

  static ThemeData get lightTheme {
    return _buildTheme(brightness: Brightness.light);
  }

  static ThemeData get darkTheme {
    return _buildTheme(brightness: Brightness.dark);
  }

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    // Deep modern dark background (OLED / Midnight Slate)
    final bgColor = isDark ? const Color(0xFF0B0F19) : AppColors.background;
    final surfaceColor = isDark ? const Color(0xFF161F30) : AppColors.surface;
    final surfaceContainerLow = isDark ? const Color(0xFF111827) : AppColors.surfaceContainerLow;
    final textHeadColor = isDark ? const Color(0xFFF9FAFB) : AppColors.textHeadings;
    final textBodyColor = isDark ? const Color(0xFFD1D5DB) : AppColors.textBody;
    final textMutedColor = isDark ? const Color(0xFF9CA3AF) : AppColors.textMuted;
    final borderColor = isDark ? const Color(0xFF2D3748) : AppColors.border;

    final primaryColor = isDark ? const Color(0xFF10B981) : AppColors.primary;
    final primaryContainer = isDark ? const Color(0xFF064E3B) : AppColors.primaryContainer;

    final textTheme = const TextTheme().copyWith(
      displayLarge: TextStyle(
        fontFamily: defaultFont,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.28,
        color: textHeadColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: defaultFont,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: textHeadColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: defaultFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        color: textHeadColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: defaultFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: textBodyColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: defaultFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: textBodyColor,
      ),
      bodySmall: TextStyle(
        fontFamily: defaultFont,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        color: textMutedColor,
      ),
      labelLarge: TextStyle(
        fontFamily: defaultFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: textHeadColor,
      ),
      labelSmall: TextStyle(
        fontFamily: defaultFont,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.12,
        color: textMutedColor,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: Colors.white,
        secondary: isDark ? const Color(0xFF94A3B8) : const Color(0xFF516071),
        onSecondary: Colors.white,
        error: isDark ? const Color(0xFFF87171) : AppColors.alert,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: textHeadColor,
        surfaceContainerLow: surfaceContainerLow,
        outline: borderColor,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: defaultFont,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textHeadColor,
        ),
        contentTextStyle: TextStyle(
          fontFamily: defaultFont,
          fontSize: 13,
          color: textBodyColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
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
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textHeadColor),
        titleTextStyle: TextStyle(
          fontFamily: defaultFont,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textHeadColor,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF1F2937),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
