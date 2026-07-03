import 'package:flutter/material.dart';

/// Centralized color palette for the GymZ Partner/User app.
///
/// Refactored to support dynamic static getters driven by the [isDark] theme flag,
/// allowing the app to transition seamlessly between dark and light themes without
/// modifying color references across the codebase.
class AppColors {
  AppColors._();

  /// Global flag toggled by the active theme provider during render setup
  static bool isDark = true;

  // Background gradient (dark slate/gray in dark mode, soft off-white/gray in light mode).
  static Color get backgroundTop => isDark ? const Color(0xFF1E2030) : const Color(0xFFF4F6FA);
  static Color get backgroundBottom => isDark ? const Color(0xFF121422) : const Color(0xFFF8FAFC);

  // Card surfaces sit on top of the background gradient.
  // In light mode, a crisp white color is used for cards.
  static Color get surfaceCard => isDark ? const Color(0xFF1B1D2A) : const Color(0xFFFFFFFF);
  static Color get surfaceCardBorder => isDark ? const Color(0xFF2E3247) : const Color(0xFFE2E8F0);

  // Pill / chip backgrounds (unselected day chips, input pills, etc).
  static Color get pillUnselected => isDark ? const Color(0xFF1B1D2A) : const Color(0xFFFFFFFF);
  static Color get pillBorder => isDark ? const Color(0xFF2E3247) : const Color(0xFFE2E8F0);

  // Primary accent: vibrant neon lime green in dark mode, vibrant cyan-to-purple in light mode.
  static Color get accentStart => isDark ? const Color(0xFFC6FF00) : const Color(0xFF00BCD4);
  static Color get accentEnd => isDark ? const Color(0xFFC6FF00) : const Color(0xFF8B5CF6);

  // Text colors.
  static Color get textPrimary => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
  static Color get textSecondary => isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  static Color get textMuted => isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  static Color get textOnAccent => isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);

  // Status colors.
  static Color get success => isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
  static Color get danger => isDark ? const Color(0xFFFF6B5B) : const Color(0xFFEF4444);
  static Color get warning => isDark ? const Color(0xFFFFB020) : const Color(0xFFF59E0B);

  // Misc.
  static Color get divider => isDark ? const Color(0xFF2E3247) : const Color(0xFFE2E8F0);
  static Color get iconCircleBg => isDark ? const Color(0x26C6FF00) : const Color(0x2600BCD4);

  // Chart and progress bar unhighlighted bar color.
  static Color get chartBarMuted => isDark ? const Color(0x40C6FF00) : const Color(0xFFCCF5FA);

  // ----------------- Compatibility Layer for Legacy References -----------------
  static Color get primary => accentStart;
  static Color get primaryLight => accentEnd;
  static Color get textOnPrimary => textOnAccent;
  
  static Color get bottomBarBg => isDark ? const Color(0xFF151824) : const Color(0xFFFFFFFF);
  static Color get surfaceCardSolid => isDark ? const Color(0xFF1F2235) : const Color(0xFFF1F5F9);
  static Color get textOnCard => textPrimary;
  
  static Color get pillBg => isDark ? const Color(0x1AC6FF00) : const Color(0x1F00BCD4);
  static Color get pillSelectedBg => accentStart;
  
  static Color get active => success;
  static Color get starColor => warning;

  static const Color tierPlatinum = Color(0xFF94A3B8);
  static const Color tierDiamond = Color(0xFF38BDF8);
  static const Color tierGold = Color(0xFFFFB020);
  static const Color tierSilver = Color(0xFFCBD5E1);
}