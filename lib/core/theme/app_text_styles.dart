import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static double textScaleFactor = 1.0;

  static TextStyle get _base => GoogleFonts.poppins();

  static TextStyle get displayLarge => _base.copyWith(
        fontSize: 28 * textScaleFactor,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get displayMedium => _base.copyWith(
        fontSize: 22 * textScaleFactor,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get sectionTitle => _base.copyWith(
        fontSize: 18 * textScaleFactor,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => _base.copyWith(
        fontSize: 15 * textScaleFactor,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 13 * textScaleFactor,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => _base.copyWith(
        fontSize: 12 * textScaleFactor,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      );

  static TextStyle get label => _base.copyWith(
        fontSize: 13 * textScaleFactor,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );

  static TextStyle get buttonLabel => _base.copyWith(
        fontSize: 16 * textScaleFactor,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnPrimary,
      );

  static TextStyle get price => _base.copyWith(
        fontSize: 18 * textScaleFactor,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      );

  static TextStyle get navLabel => _base.copyWith(
        fontSize: 11 * textScaleFactor,
        fontWeight: FontWeight.w500,
      );
}