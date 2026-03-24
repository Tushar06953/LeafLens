import 'package:flutter/material.dart';

class AppColors {
  // Light app surfaces (main theme)
  static const g1 = Color(0xFFF4FBF0); // very light sage — scaffold bg
  static const g2 = Color(0xFFE5F5DC); // light sage — cards
  static const g3 = Color(0xFFCCE8C0); // medium sage — borders / dividers

  // Accent greens (unchanged)
  static const ga = Color(0xFF2A7A50);
  static const gb = Color(0xFF3DA876);
  static const gc = Color(0xFF4CAF78); // slightly deeper for contrast on light bg

  // Light surfaces
  static const cream = Color(0xFFF5F0E8);
  static const warm  = Color(0xFFFFFFFF); // pure white

  // Accent gold (Plant of Day)
  static const gold  = Color(0xFFC8951A);
  static const gold2 = Color(0xFFE8B84B);

  // Text — dark (for light backgrounds)
  static const text1 = Color(0xFF1C3A1C); // dark green-charcoal
  static const text2 = Color(0xFF4A6A42); // medium green
  static const text3 = Color(0xFF8AAD82); // muted green

  // Light-screen text
  static const darkText  = Color(0xFF1A1A1A);
  static const mutedText = Color(0xFF777777);

  // Dark screen colors — used by Splash, Analyzing (camera / animation screens)
  static const dark1 = Color(0xFF0B1F12);
  static const dark2 = Color(0xFF163024);
  static const dark3 = Color(0xFF1F4233);
}
