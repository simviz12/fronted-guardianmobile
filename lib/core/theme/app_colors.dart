import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Canvas / Background (High-contrast pure light & clean slate)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F5F9);
  static const Color surfaceContainer = Color(0xFFE2E8F0);

  // Modern Dark palette (OLED / Pitch Black & Slate)
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF111111);
  static const Color darkSurfaceContainerLow = Color(0xFF181818);
  static const Color darkSurfaceContainer = Color(0xFF242424);
  static const Color darkBorder = Color(0xFF2E2E2E);

  // Primary Accent (Clean Emerald / Tactical Cyber Green)
  static const Color primary = Color(0xFF0F9F66);
  static const Color primaryDark = Color(0xFF0A7E50);
  static const Color primaryLight = Color(0xFF22C55E);
  static const Color primaryContainer = Color(0xFF0F9F66);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primarySubtle = Color(0xFFE6F7F0);

  // Neutral / Typography (Pure High Contrast)
  static const Color textHeadings = Color(0xFF0F172A);
  static const Color textBody = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

  // Dark text typography
  static const Color darkTextHeadings = Color(0xFFFFFFFF);
  static const Color darkTextBody = Color(0xFFE2E8F0);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Semantic Status
  static const Color safe = Color(0xFF10B981);
  static const Color safeSubtle = Color(0xFFECFDF5);
  static const Color safeText = Color(0xFF047857);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSubtle = Color(0xFFFFFBEB);
  static const Color warningText = Color(0xFFB45309);

  static const Color alert = Color(0xFFEF4444);
  static const Color alertContainer = Color(0xFFFEF2F2);
  static const Color alertText = Color(0xFFDC2626);

  static const Color neutralBadge = Color(0xFFF1F5F9);
  static const Color neutralBadgeText = Color(0xFF475569);
  static const Color darkNeutralBadge = Color(0xFF1E293B);
  static const Color darkNeutralBadgeText = Color(0xFF94A3B8);

  // Accent Blue / Cyan for secondary info cards
  static const Color infoBlue = Color(0xFF0284C7);
  static const Color infoBlueSubtle = Color(0xFFF0F9FF);
}
