// Guardian Mobile — ThemeData built from the tokens.
// Uses the Plus Jakarta Sans font bundled in assets/fonts (works offline).
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'guardian_tokens.dart';

const _font = 'Plus Jakarta Sans';

extension GuardianContext on BuildContext {
  /// `context.gm.brand`, `context.gm.inkMuted`, …
  ///
  /// Falls back to the brightness-matching palette when the ambient theme
  /// wasn't built by [GuardianTheme] (tests, third-party themed subtrees).
  GColors get gm {
    final theme = Theme.of(this);
    return theme.extension<GColors>() ??
        (theme.brightness == Brightness.dark ? GColors.dark : GColors.light);
  }
  TextTheme get text => Theme.of(this).textTheme;
}

abstract final class GuardianTheme {
  static ThemeData light() => _build(GColors.light, Brightness.light);
  static ThemeData dark() => _build(GColors.dark, Brightness.dark);

  static TextTheme _text(GColors c) {
    TextStyle s(double size, double height, FontWeight w, {double ls = 0, Color? color}) => TextStyle(
        fontFamily: _font, fontSize: size, height: height / size, fontWeight: w, letterSpacing: ls, color: color ?? c.ink);
    return TextTheme(
      displayLarge: s(28, 36, FontWeight.w800, ls: -0.6),
      displayMedium: s(24, 32, FontWeight.w800, ls: -0.4),
      headlineLarge: s(22, 30, FontWeight.w700, ls: -0.3),
      headlineMedium: s(20, 28, FontWeight.w700, ls: -0.2),
      titleSmall: s(13, 18, FontWeight.w600),
      labelMedium: s(12, 16, FontWeight.w600),
      displaySmall: s(30, 36, FontWeight.w800, ls: -0.6),           // display
      headlineSmall: s(22, 28, FontWeight.w700, ls: -0.2),          // title-lg
      titleLarge: s(18, 24, FontWeight.w700),                       // title
      titleMedium: s(16, 22, FontWeight.w700),                      // headline
      bodyLarge: s(15, 22, FontWeight.w500),                        // body
      bodyMedium: s(13, 18, FontWeight.w500, color: c.inkMuted),    // body-sm
      labelLarge: s(14, 20, FontWeight.w700),                       // label
      labelSmall: s(11, 16, FontWeight.w800, ls: 1.1, color: c.inkMuted), // overline
      bodySmall: s(12, 16, FontWeight.w600, color: c.inkMuted),     // caption
    );
  }

  /// Coordinates, URLs, IDs: monospace with tabular figures.
  static TextStyle mono(BuildContext context) => TextStyle(
        fontFamily: 'monospace', fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w500, color: context.gm.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static ThemeData _build(GColors c, Brightness b) {
    final scheme = ColorScheme(
      brightness: b,
      primary: c.brand, onPrimary: c.onBrand,
      primaryContainer: c.brandSoft, onPrimaryContainer: c.brandInk,
      secondary: c.brandInk, onSecondary: c.onBrand,
      error: c.danger, onError: c.onDanger,
      errorContainer: c.dangerSoft, onErrorContainer: c.dangerInk,
      surface: c.surface, onSurface: c.ink, onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: c.bg, surfaceContainerHighest: c.surfaceSunken,
      outline: c.borderStrong, outlineVariant: c.border, scrim: c.scrim,
    );
    final text = _text(c);
    final shapeMd = RoundedRectangleBorder(borderRadius: GRadius.rMd);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      fontFamily: _font,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      textTheme: text,
      extensions: [c],
      splashFactory: InkSparkle.splashFactory,
      // Page transitions: shared-axis-like fade + slide on every platform.
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg, surfaceTintColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 1,
        shadowColor: Colors.black12, centerTitle: false, titleTextStyle: text.titleLarge, foregroundColor: c.ink,
      ),
      cardTheme: CardThemeData(
        color: c.surface, surfaceTintColor: Colors.transparent, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: GRadius.rLg, side: BorderSide(color: c.border)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: const Size(64, GSpace.s12), shape: shapeMd, textStyle: text.labelLarge,
        backgroundColor: c.brand, foregroundColor: c.onBrand, animationDuration: GMotion.fast,
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, GSpace.s12), shape: shapeMd, textStyle: text.labelLarge,
        foregroundColor: c.brandInk, side: BorderSide(color: c.borderStrong),
      )),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
        minimumSize: const Size(48, 40), shape: shapeMd, textStyle: text.labelLarge, foregroundColor: c.inkMuted,
      )),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: c.surfaceSunken,
        contentPadding: const EdgeInsets.symmetric(horizontal: GSpace.s4, vertical: 15),
        prefixIconColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.error)
            ? c.dangerInk : s.contains(WidgetState.focused) ? c.brandInk : c.inkMuted),
        hintStyle: text.bodyLarge?.copyWith(color: c.inkMuted),
        labelStyle: text.bodyLarge?.copyWith(color: c.inkMuted),
        border: OutlineInputBorder(borderRadius: GRadius.rMd, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: GRadius.rMd, borderSide: const BorderSide(color: Colors.transparent, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: GRadius.rMd, borderSide: BorderSide(color: c.brand, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: GRadius.rMd, borderSide: BorderSide(color: c.danger, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: GRadius.rMd, borderSide: BorderSide(color: c.danger, width: 1.5)),
        errorStyle: text.bodySmall?.copyWith(color: c.dangerInk),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? c.onBrand : c.borderStrong),
        trackColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? c.brand : c.surfaceSunken),
        trackOutlineColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.transparent : c.borderStrong),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(style: SegmentedButton.styleFrom(
        backgroundColor: c.surfaceSunken, selectedBackgroundColor: c.surface,
        foregroundColor: c.inkMuted, selectedForegroundColor: c.ink, side: BorderSide.none,
        textStyle: text.labelLarge, shape: const StadiumBorder(),
      )),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface, selectedColor: c.brandSoft, labelStyle: text.labelLarge,
        side: BorderSide(color: c.borderStrong), shape: const StadiumBorder(), showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface, surfaceTintColor: Colors.transparent, indicatorColor: c.brandSoft, height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => text.bodySmall?.copyWith(
            fontWeight: FontWeight.w700, color: s.contains(WidgetState.selected) ? c.brandInk : c.inkMuted)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            size: 22, color: s.contains(WidgetState.selected) ? c.brandInk : c.inkMuted)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface, surfaceTintColor: Colors.transparent, showDragHandle: true,
        dragHandleColor: c.borderStrong, dragHandleSize: const Size(40, 4),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(GRadius.xl))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating, backgroundColor: c.ink,
        contentTextStyle: text.labelLarge?.copyWith(color: c.bg),
        shape: RoundedRectangleBorder(borderRadius: GRadius.rMd),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
    );
  }
}
