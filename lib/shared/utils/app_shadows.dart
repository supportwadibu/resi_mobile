import 'package:flutter/material.dart';

/// Constantes d'ombres pour maintenir une cohérence UI dans l'application.
///
/// Utilisation:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     boxShadow: AppShadows.cardShadow,
///   ),
/// )
/// ```
class AppShadows {
  AppShadows._();

  // Ombres de base
  static List<BoxShadow> get none => [];

  static List<BoxShadow> get xs => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get xl => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  // Ombres spécifiques
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get floatingButtonShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.20),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get bottomSheetShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
      ];

  static List<BoxShadow> get dropdownShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get inputFocusShadow => [
        BoxShadow(
          color: Colors.green.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // Ombres colorées (pour les boutons primaires par exemple)
  static List<BoxShadow> coloredShadow(Color color, {double opacity = 0.3}) => [
        BoxShadow(
          color: color.withOpacity(opacity),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}
