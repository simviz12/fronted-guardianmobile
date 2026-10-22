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

    // High contrast black & white design
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final surfaceContainerLow = isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow;
    final textHeadColor = isDark ? AppColors.darkTextHeadings : AppColors.textHeadings;
    final textBodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final textMutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final primaryContainer = isDark ? const Color(0xFF064E3B) : AppColors.primarySubtle;

    final textTheme = const TextTheme().copyWith(
      displayLarge: TextStyle(
        fontFamily: defaultFont,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 36 / 28,
        letterSpacing: -0.5,
        color: textHeadColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: defaultFont,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 28 / 20,
        color: textHeadColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: defaultFont,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 24 / 16,
        color: textHeadColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: defaultFont,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 22 / 15,
        color: textBodyColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: defaultFont,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 18 / 13,
        color: textBodyColor,
      ),
      bodySmall: TextStyle(
        fontFamily: defaultFont,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        color: textMutedColor,
      ),
      labelLarge: TextStyle(
        fontFamily: defaultFont,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 18 / 13,
        color: textHeadColor,
      ),
      labelSmall: TextStyle(
        fontFamily: defaultFont,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 14 / 11,
        letterSpacing: 0.2,
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
        onPrimaryContainer: isDark ? Colors.white : AppColors.primaryDark,
        secondary: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        onSecondary: Colors.white,
        error: isDark ? const Color(0xFFEF4444) : AppColors.alert,
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
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: borderColor, width: 1.2),
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
            fontWeight: FontWeight.w700,
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
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: textHeadColor,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        textColor: textHeadColor,
        iconColor: textMutedColor,
        titleTextStyle: TextStyle(
          fontFamily: defaultFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textHeadColor,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: defaultFont,
          fontSize: 12,
          color: textMutedColor,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
