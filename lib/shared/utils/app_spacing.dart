/// Constantes d'espacement pour maintenir une cohérence UI dans l'application.
/// 
/// Utilisation:
/// ```dart
/// SizedBox(height: AppSpacing.md)
/// Padding(padding: EdgeInsets.all(AppSpacing.lg))
/// ```
class AppSpacing {
  AppSpacing._();

  // Espacements de base
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Espacements spécifiques pour les sections
  static const double sectionTop = 20.0;
  static const double sectionBottom = 20.0;
  static const double sectionHorizontal = 16.0;

  // Espacements pour les cards
  static const double cardPadding = 16.0;
  static const double cardMargin = 12.0;
  static const double cardGap = 12.0;

  // Espacements pour les listes
  static const double listItemSpacing = 12.0;
  static const double listPadding = 16.0;

  // Espacements pour les formulaires
  static const double formFieldSpacing = 16.0;
  static const double formSectionSpacing = 24.0;
  static const double formLabelSpacing = 8.0;

  // Espacements pour les boutons
  static const double buttonPadding = 16.0;
  static const double buttonSpacing = 12.0;

  // Espacements pour les bottom sheets
  static const double bottomSheetPadding = 16.0;
  static const double bottomSheetHandleTop = 12.0;

  // Espacements pour les dialogues
  static const double dialogPadding = 24.0;
  static const double dialogContentSpacing = 16.0;
}

