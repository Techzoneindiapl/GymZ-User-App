import 'package:flutter/material.dart';

/// Color palette for the GymZ User app.
///
/// Key difference from the Partner app: the primary accent here is
/// orange (#FF6B00) rather than cream/peach, matching the user-facing
/// brand identity seen across all 12 screens.
class AppColors {
  AppColors._();

  // Background gradient — same deep blue as partner app.
  static const Color backgroundTop = Color(0xFF1A1FB8);
  static const Color backgroundBottom = Color(0xFF0E126B);

  // Card surfaces.
  static const Color surfaceCard = Color(0x334A55E8);
  static const Color surfaceCardSolid = Color(0xFF1E2580);
  static const Color surfaceCardBorder = Color(0x33FFFFFF);

  // Primary accent — orange, used for CTAs, selected states, highlights.
  static const Color primary = Color(0xFFFF6B00);
  static const Color primaryLight = Color(0xFFFF8C38);

  // Text colors.
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xCCE3E6FF);
  static const Color textMuted = Color(0x99C7CCFF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnCard = Color(0xFFFFFFFF);

  // Pill / chip.
  static const Color pillBg = Color(0x4D5662F5);
  static const Color pillBorder = Color(0x66FFFFFF);
  static const Color pillSelectedBg = Color(0xFFFF6B00);

  // Status.
  static const Color success = Color(0xFF34D399);
  static const Color danger = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFFB020);
  static const Color active = Color(0xFF4ADE80);

  // Misc.
  static const Color divider = Color(0x1FFFFFFF);
  static const Color iconCircleBg = Color(0x29FFFFFF);
  static const Color starColor = Color(0xFFFFB020);

  // Tier colors.
  static const Color tierPlatinum = Color(0xFF94A3B8);
  static const Color tierDiamond = Color(0xFF38BDF8);
  static const Color tierGold = Color(0xFFFFB020);
  static const Color tierSilver = Color(0xFFCBD5E1);
}