import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  // Display / Headings — Cormorant Garamond
  static TextStyle get display => GoogleFonts.cormorantGaramond(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
        letterSpacing: 0.5,
      );

  static TextStyle get heading1 => GoogleFonts.cormorantGaramond(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      );

  static TextStyle get heading2 => GoogleFonts.cormorantGaramond(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      );

  static TextStyle get heading3 => GoogleFonts.cormorantGaramond(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      );

  // Body / UI — Outfit
  static TextStyle get body => GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.darkText,
      );

  static TextStyle get bodySmall => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.mutedText,
      );

  static TextStyle get caption => GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.mutedText,
      );

  static TextStyle get label => GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
      );

  static TextStyle get tagline => GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.mutedText,
        letterSpacing: 1.5,
      );

  static TextStyle get button => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      );
}
