import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds
  static const Color background = Color(0xFFF5F4F8);
  static const Color surface = Color(0xFFF5F4F8);

  // ── Base
  static const Color black = Color(0xFF000000);
  static const Color primary = Color(0xFF3322AC);
  static const Color primaryDark = Color.fromARGB(255, 15, 7, 78);

  // ── Dégradé
  static const Color gradientStart = Color(0xFF14A985); // 12%
  static const Color gradientMid = Color(0xFF3A8CA9); // 58%
  static const Color gradientEnd = Color(0xFF9747FF); // 100%

  // ── Gradient object prêt à l'emploi
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.12, 0.58, 1.0],
    colors: [gradientStart, gradientMid, gradientEnd],
  );

  // ── Utilitaires
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey100 = Color(0xFFF0F0F0);
  static const Color grey200 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);

  // ── Statuts
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF4F46E5);

  // ── Statuts background (version claire)
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color infoBg = Color(0xFFEEF2FF);

  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF8A8A9A);
  static const Color textLight = Color(0xFFB0B0C0);
  static const Color green = Color(0xFF2ECC71);
  static const Color red = Color(0xFFE74C3C);
  static const Color chartLine = Color(0xFF2ECC71);
  static const Color chartDot = Color(0xFF2ECC71);
  static const Color chartGrid = Color(0xFFE8E8F0);
  static const Color divider = Color(0xFFEEEEF5);
}
