import 'package:flutter/material.dart';

/// Guardian Sentinel palette.
///
/// Constant names are part of the public API used across every screen; only
/// the values were refined (cooler neutrals, deeper emerald, softer dark mode)
/// so the whole app picks up the new look without per-screen changes.
class AppColors {
  AppColors._();

  // Canvas / Background (cool, airy light surfaces)
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF3FA);
  static const Color surfaceContainer = Color(0xFFE3E9F4);

  // Dark palette (deep navy-slate instead of pure black: less eye strain and
  // keeps elevation visible on OLED screens)
  static const Color darkBackground = Color(0xFF070B14);
  static const Color darkSurface = Color(0xFF0F1522);
  static const Color darkSurfaceContainerLow = Color(0xFF151C2B);
  static const Color darkSurfaceContainer = Color(0xFF1C2536);
  static const Color darkBorder = Color(0xFF253047);

  // Primary Accent (Guardian emerald)
  static const Color primary = Color(0xFF00855C);
  static const Color primaryDark = Color(0xFF006948);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryContainer = Color(0xFF00855C);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primarySubtle = Color(0xFFE3F8EF);

  // Neutral / Typography
  static const Color textHeadings = Color(0xFF0B1C30);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

  // Dark typography
  static const Color darkTextHeadings = Color(0xFFF8FAFC);
  static const Color darkTextBody = Color(0xFFD5DEEA);
  static const Color darkTextMuted = Color(0xFF8C9AB0);

  // Semantic Status
  static const Color safe = Color(0xFF10B981);
  static const Color safeSubtle = Color(0xFFECFDF5);
  static const Color safeText = Color(0xFF047857);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSubtle = Color(0xFFFFFBEB);
  static const Color warningText = Color(0xFFB45309);

  static const Color alert = Color(0xFFE5484D);
  static const Color alertContainer = Color(0xFFFEF2F2);
  static const Color alertText = Color(0xFFC62828);

  static const Color neutralBadge = Color(0xFFF1F5F9);
  static const Color neutralBadgeText = Color(0xFF475569);
  static const Color darkNeutralBadge = Color(0xFF1E293B);
  static const Color darkNeutralBadgeText = Color(0xFF94A3B8);

  // Accent Blue / Cyan for secondary info cards
  static const Color infoBlue = Color(0xFF0284C7);
  static const Color infoBlueSubtle = Color(0xFFF0F9FF);

  /// Brand gradient used by hero headers and primary CTAs.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00A26F), Color(0xFF006948)],
  );
}
