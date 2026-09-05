import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the Jenga companion app.
/// Warm-wood, tactile, premium-party-game aesthetic.
class AppColors {
  AppColors._();

  static const cream = Color(0xFFF5EFE4);
  static const creamDim = Color(0xFFEAE1D1);
  static const walnut = Color(0xFF2E2019);
  static const walnutSoft = Color(0xFF6B5A4E);

  static const amber = Color(0xFFC17F3E);
  static const amberDeep = Color(0xFFA2652C);
  static const amberPale = Color(0xFFEAC79A);

  static const felt = Color(0xFF2F5D4F);
  static const feltPale = Color(0xFFDCEAE4);

  static const coral = Color(0xFFD3654B);
  static const coralPale = Color(0xFFF6DCD3);

  static const gold = Color(0xFFD8A73D);
  static const silver = Color(0xFF9AA0A6);
  static const bronze = Color(0xFFB57A4E);

  static const cardShadow = Color(0x1F2E2019);
}

class AppRadius {
  AppRadius._();
  static const lg = 28.0;
  static const md = 18.0;
  static const sm = 12.0;
}

class AppText {
  AppText._();

  // Display face — game moments, turn names, headlines.
  static TextStyle display({
    double size = 30,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.walnut,
  }) => GoogleFonts.fraunces(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: -0.2,
    height: 1.15,
  );

  // Body / UI face.
  static TextStyle body({
    double size = 15,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.walnut,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.4,
  );

  // Small uppercase labels ("MAYA'S TURN", section eyebrows).
  static TextStyle eyebrow({
    double size = 12.5,
    Color color = AppColors.amberDeep,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: FontWeight.w800,
    color: color,
    letterSpacing: 1.1,
  );

  // Numeric / data face — block counts, scores, diagnostics.
  static TextStyle mono({
    double size = 13,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.walnut,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
  );
}

ThemeData buildJengaTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.amber,
      brightness: Brightness.light,
      surface: AppColors.cream,
    ),
    fontFamily: GoogleFonts.inter().fontFamily,
    splashFactory: InkRipple.splashFactory,
  );
}
