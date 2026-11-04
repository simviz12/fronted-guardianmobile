import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  /// Bundled in assets/fonts (works offline, no runtime font download).
  static const defaultFont = 'Plus Jakarta Sans';

  static ThemeData get lightTheme => _buildTheme(brightness: Brightness.light);

  static ThemeData get darkTheme => _buildTheme(brightness: Brightness.dark);

  /// Status/navigation bar styling for edge-to-edge rendering.
  static SystemUiOverlayStyle overlayStyleFor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final surfaceContainerLow =
        isDark ? AppColors.darkSurfaceContainerLow : AppColors.surfaceContainerLow;
    final surfaceContainer = isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceContainer;
    final textHeadColor = isDark ? AppColors.darkTextHeadings : AppColors.textHeadings;
    final textBodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final textMutedColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final onPrimaryColor = isDark ? const Color(0xFF002114) : Colors.white;
    final primaryContainer = isDark ? const Color(0xFF053B2A) : AppColors.primarySubtle;
    final errorColor = isDark ? const Color(0xFFFF6B6B) : AppColors.alert;

    TextStyle style(double size, FontWeight weight, double lineHeight, Color color,
            {double letterSpacing = 0}) =>
        TextStyle(
          fontFamily: defaultFont,
          fontSize: size,
          fontWeight: weight,
          height: lineHeight / size,
          letterSpacing: letterSpacing,
          color: color,
        );

    final textTheme = TextTheme(
      displayLarge: style(28, FontWeight.w800, 36, textHeadColor, letterSpacing: -0.6),
      displayMedium: style(24, FontWeight.w800, 32, textHeadColor, letterSpacing: -0.4),
      displaySmall: style(22, FontWeight.w700, 30, textHeadColor, letterSpacing: -0.3),
      headlineLarge: style(22, FontWeight.w700, 30, textHeadColor, letterSpacing: -0.3),
      headlineMedium: style(20, FontWeight.w700, 28, textHeadColor, letterSpacing: -0.2),
      headlineSmall: style(16, FontWeight.w700, 24, textHeadColor),
      titleLarge: style(18, FontWeight.w700, 26, textHeadColor, letterSpacing: -0.2),
      titleMedium: style(15, FontWeight.w600, 22, textHeadColor),
      titleSmall: style(13, FontWeight.w600, 18, textHeadColor),
      bodyLarge: style(15, FontWeight.w500, 22, textBodyColor),
      bodyMedium: style(13, FontWeight.w400, 19, textBodyColor),
      bodySmall: style(12, FontWeight.w400, 16, textMutedColor),
      labelLarge: style(13, FontWeight.w700, 18, textHeadColor),
      labelMedium: style(12, FontWeight.w600, 16, textHeadColor),
      labelSmall: style(11, FontWeight.w600, 14, textMutedColor, letterSpacing: 0.2),
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primaryColor,
      onPrimary: onPrimaryColor,
      primaryContainer: primaryContainer,
      onPrimaryContainer: isDark ? const Color(0xFFA7F3D0) : AppColors.primaryDark,
      secondary: isDark ? const Color(0xFF94A3B8) : const Color(0xFF516071),
      onSecondary: Colors.white,
      secondaryContainer: isDark ? const Color(0xFF1E293B) : const Color(0xFFD4E4F8),
      onSecondaryContainer: isDark ? const Color(0xFFD5DEEA) : const Color(0xFF394858),
      tertiary: isDark ? const Color(0xFF7DD3FC) : AppColors.infoBlue,
      onTertiary: Colors.white,
      error: errorColor,
      onError: Colors.white,
      errorContainer: isDark ? const Color(0xFF4C1515) : AppColors.alertContainer,
      onErrorContainer: isDark ? const Color(0xFFFFB4AB) : AppColors.alertText,
      surface: surfaceColor,
      onSurface: textHeadColor,
      onSurfaceVariant: textMutedColor,
      surfaceContainerLowest: isDark ? AppColors.darkBackground : Colors.white,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainer,
      surfaceContainerHighest: isDark ? const Color(0xFF243049) : const Color(0xFFD3E4FE),
      outline: borderColor,
      outlineVariant: isDark ? const Color(0xFF1C2536) : const Color(0xFFEDF1F7),
      shadow: const Color(0xFF0B1C30),
      scrim: Colors.black,
      inverseSurface: isDark ? AppColors.darkTextHeadings : const Color(0xFF213145),
      onInverseSurface: isDark ? AppColors.darkBackground : const Color(0xFFEAF1FF),
      inversePrimary: isDark ? AppColors.primary : const Color(0xFF65DCA8),
      surfaceTint: Colors.transparent,
    );

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg));
    final buttonTextStyle = style(15, FontWeight.w700, 20, onPrimaryColor);

    OutlineInputBorder inputBorder(Color color, [double width = 1.2]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: defaultFont,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bgColor,
      canvasColor: bgColor,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      dividerColor: borderColor,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl + 4)),
        titleTextStyle: style(18, FontWeight.w700, 26, textHeadColor),
        contentTextStyle: style(14, FontWeight.w400, 21, textBodyColor),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          disabledBackgroundColor: primaryColor.withValues(alpha: 0.38),
          disabledForegroundColor: onPrimaryColor.withValues(alpha: 0.8),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: buttonShape,
          textStyle: buttonTextStyle,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: buttonShape,
          textStyle: buttonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textHeadColor,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: buttonShape,
          side: BorderSide(color: borderColor, width: 1.2),
          textStyle: style(15, FontWeight.w700, 20, textHeadColor),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          textStyle: style(14, FontWeight.w700, 20, primaryColor),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textHeadColor,
          minimumSize: const Size(44, 44),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg + 2)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: style(14, FontWeight.w400, 20, textMutedColor),
        labelStyle: style(14, FontWeight.w500, 20, textMutedColor),
        floatingLabelStyle: style(13, FontWeight.w600, 18, primaryColor),
        prefixIconColor: textMutedColor,
        suffixIconColor: textMutedColor,
        errorStyle: style(12, FontWeight.w500, 16, errorColor),
        border: inputBorder(Colors.transparent),
        enabledBorder: inputBorder(Colors.transparent),
        focusedBorder: inputBorder(primaryColor, 1.6),
        errorBorder: inputBorder(errorColor),
        focusedErrorBorder: inputBorder(errorColor, 1.6),
        disabledBorder: inputBorder(Colors.transparent),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textHeadColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: borderColor,
        centerTitle: false,
        systemOverlayStyle: overlayStyleFor(brightness),
        iconTheme: IconThemeData(color: textHeadColor),
        titleTextStyle: style(18, FontWeight.w700, 24, textHeadColor, letterSpacing: -0.2),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surfaceColor,
        showDragHandle: true,
        dragHandleColor: borderColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl + 4)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        textColor: textHeadColor,
        iconColor: textMutedColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minVerticalPadding: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        titleTextStyle: style(14, FontWeight.w600, 20, textHeadColor),
        subtitleTextStyle: style(12, FontWeight.w400, 17, textMutedColor),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primaryColor : null,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.transparent : borderColor,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: textMutedColor, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primaryColor : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(onPrimaryColor),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLow,
        selectedColor: primaryContainer,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.full)),
        labelStyle: style(12, FontWeight.w600, 16, textHeadColor),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          ),
          textStyle: WidgetStatePropertyAll(style(13, FontWeight.w600, 18, textHeadColor)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(style(12, FontWeight.w600, 16, textHeadColor)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: textMutedColor,
        indicatorColor: primaryColor,
        dividerColor: borderColor,
        labelStyle: style(14, FontWeight.w700, 20, primaryColor),
        unselectedLabelStyle: style(14, FontWeight.w600, 20, textMutedColor),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceContainer,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 4,
      ),
      dividerTheme: DividerThemeData(color: borderColor, thickness: 1, space: 1),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceContainer : const Color(0xFF0B1C30),
          borderRadius: BorderRadius.circular(AppRadii.regular),
        ),
        textStyle: style(12, FontWeight.w500, 16, Colors.white),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurfaceContainer : const Color(0xFF0B1C30),
        contentTextStyle: style(14, FontWeight.w500, 20, Colors.white),
        actionTextColor: AppColors.primaryLight,
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
      ),
    );
  }
}
