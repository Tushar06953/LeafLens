import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.g1,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gb,
          secondary: AppColors.gc,
          surface: AppColors.g2,
          error: Color(0xFFCF6679),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.text1),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gb,
            foregroundColor: AppColors.darkText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.g3,
          selectedColor: AppColors.gb,
          labelStyle: GoogleFonts.outfit(fontSize: 12, color: AppColors.text1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.gb,
          unselectedLabelColor: AppColors.text2,
          indicatorColor: AppColors.gb,
          labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
        ),
      );
}
