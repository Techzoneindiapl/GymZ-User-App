import 'package:flutter/material.dart';

/// Color palette for the GymZ User app.
///
/// Key difference from the Partner app: the primary accent here is
/// orange (#FF6B00) rather than cream/peach, matching the user-facing
/// brand identity seen across all 12 screens.
class AppColors {
  AppColors._();

  /// Global flag to determine whether the app is in dark or light mode.
  /// Managed dynamically by the theme notifier in main.dart.
  static bool isDark = true;

  // Background gradient — same deep blue as partner app in dark mode,
  // premium cool grey/indigo in light mode.
  static Color get backgroundTop => isDark ? const Color(0xFF1A1FB8) : const Color(0xFFEEF2F6);
  static Color get backgroundBottom => isDark ? const Color(0xFF0E126B) : const Color(0xFFD8E2EF);

  // Bottom Navigation Bar background.
  static Color get bottomBarBg => isDark ? const Color(0xFF111666) : const Color(0xFFFFFFFF);

  // Card surfaces.
  static Color get surfaceCard => isDark ? const Color(0x334A55E8) : const Color(0xFFFFFFFF);
  static Color get surfaceCardSolid => isDark ? const Color(0xFF1E2580) : const Color(0xFFF1F5F9);
  static Color get surfaceCardBorder => isDark ? const Color(0x33FFFFFF) : const Color(0x1F000000);

  // Primary accent — orange, used for CTAs, selected states, highlights.
  static const Color primary = Color(0xFFFF6B00);
  static const Color primaryLight = Color(0xFFFF8C38);

  // Text colors.
  static Color get textPrimary => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
  static Color get textSecondary => isDark ? const Color(0xCCE3E6FF) : const Color(0xFF334155);
  static Color get textMuted => isDark ? const Color(0x99C7CCFF) : const Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static Color get textOnCard => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);

  // Pill / chip.
  static Color get pillBg => isDark ? const Color(0x4D5662F5) : const Color(0x1F4A55E8);
  static Color get pillBorder => isDark ? const Color(0x66FFFFFF) : const Color(0x1F000000);
  static const Color pillSelectedBg = Color(0xFFFF6B00);

  // Status.
  static const Color success = Color(0xFF34D399);
  static const Color danger = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFFB020);
  static const Color active = Color(0xFF4ADE80);

  // Misc.
  static Color get divider => isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000);
  static Color get iconCircleBg => isDark ? const Color(0x29FFFFFF) : const Color(0x14000000);
  static const Color starColor = Color(0xFFFFB020);

  // Tier colors.
  static const Color tierPlatinum = Color(0xFF94A3B8);
  static const Color tierDiamond = Color(0xFF38BDF8);
  static const Color tierGold = Color(0xFFFFB020);
  static const Color tierSilver = Color(0xFFCBD5E1);
}