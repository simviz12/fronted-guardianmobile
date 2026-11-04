import 'package:flutter/material.dart';

/// Legacy palette API used across every screen.
///
/// Values are mapped to the Guardian Mobile design-system tokens
/// (see guardian_tokens.dart → GColors.light / GColors.dark) so existing
/// screens pick up the new design without per-screen changes. New code should
/// prefer `context.gm` (theme-aware tokens) over these constants.
class AppColors {
  AppColors._();

  // Canvas / Background (GColors.light)
  static const Color background = Color(0xFFF3F6F4); // bg
  static const Color surface = Color(0xFFFFFFFF); // surface
  static const Color surfaceContainerLow = Color(0xFFEBF0ED); // surfaceSunken
  static const Color surfaceContainer = Color(0xFFDFE6E2); // border

  // Dark palette (GColors.dark)
  static const Color darkBackground = Color(0xFF0B110F); // bg
  static const Color darkSurface = Color(0xFF131B18); // surface
  static const Color darkSurfaceContainerLow = Color(0xFF1A2420); // surfaceSunken
  static const Color darkSurfaceContainer = Color(0xFF1C2622); // surfaceRaised
  static const Color darkBorder = Color(0xFF26322D); // border

  // Primary Accent (brand)
  static const Color primary = Color(0xFF047A55); // brand
  static const Color primaryDark = Color(0xFF035E42); // brandPressed
  static const Color primaryLight = Color(0xFF2FBF8F); // dark brand
  static const Color primaryContainer = Color(0xFF047A55);
  static const Color onPrimary = Color(0xFFFFFFFF); // onBrand
  static const Color primarySubtle = Color(0xFFE2F4EB); // brandSoft

  // Neutral / Typography
  static const Color textHeadings = Color(0xFF0E1A15); // ink
  static const Color textBody = Color(0xFF2E3D37);
  static const Color textMuted = Color(0xFF56665F); // inkMuted
  static const Color border = Color(0xFFDFE6E2); // border

  // Dark typography
  static const Color darkTextHeadings = Color(0xFFECF3EF); // ink
  static const Color darkTextBody = Color(0xFFC9D6D0);
  static const Color darkTextMuted = Color(0xFF9BADA5); // inkMuted

  // Semantic Status
  static const Color safe = Color(0xFF047A55); // brand
  static const Color safeSubtle = Color(0xFFE2F4EB); // brandSoft
  static const Color safeText = Color(0xFF04603F); // brandInk

  static const Color warning = Color(0xFFB45309);
  static const Color warningSubtle = Color(0xFFFEF3E2); // warningSoft
  static const Color warningText = Color(0xFF8A3F06); // warningInk

  static const Color alert = Color(0xFFC62A31); // danger
  static const Color alertContainer = Color(0xFFFDECED); // dangerSoft
  static const Color alertText = Color(0xFF9F1A21); // dangerInk

  static const Color neutralBadge = Color(0xFFEBF0ED); // surfaceSunken
  static const Color neutralBadgeText = Color(0xFF56665F); // inkMuted
  static const Color darkNeutralBadge = Color(0xFF1A2420);
  static const Color darkNeutralBadgeText = Color(0xFF9BADA5);

  // Info
  static const Color infoBlue = Color(0xFF1F5FD6); // info
  static const Color infoBlueSubtle = Color(0xFFE7EFFF); // infoSoft

  /// Brand gradient used by hero headers and primary CTAs.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF079466), Color(0xFF035E42)],
  );
}
