import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.g1,
        colorScheme: const ColorScheme.light(
          primary: AppColors.gb,
          secondary: AppColors.gc,
          surface: AppColors.warm,
          error: Color(0xFFB00020),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          iconTheme: IconThemeData(color: AppColors.darkText),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gb,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.g2,
          selectedColor: AppColors.gb,
          labelStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.darkText),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.ga,
          unselectedLabelColor: AppColors.mutedText,
          indicatorColor: AppColors.ga,
          labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
        ),
        cardColor: AppColors.warm,
        dividerColor: AppColors.g3,
      );

  // Keep alias so main.dart compiles unchanged
  static ThemeData get dark => light;
}
