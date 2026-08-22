/// Constantes de durées d'animation pour maintenir une cohérence UI.
///
/// Utilisation:
/// ```dart
/// AnimatedContainer(duration: AppDurations.medium)
/// Future.delayed(AppDurations.snackbar)
/// ```
class AppDurations {
  AppDurations._();

  // Durées de base pour les animations
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 500);
  static const Duration slowest = Duration(milliseconds: 700);

  // Durées spécifiques
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration bottomSheet = Duration(milliseconds: 250);
  static const Duration dialog = Duration(milliseconds: 200);
  static const Duration snackbar = Duration(seconds: 3);
  static const Duration snackbarShort = Duration(seconds: 2);
  static const Duration snackbarLong = Duration(seconds: 5);
  static const Duration tooltip = Duration(seconds: 2);
  static const Duration splash = Duration(seconds: 2);
  static const Duration shimmer = Duration(milliseconds: 1500);
  static const Duration debounce = Duration(milliseconds: 500);
  static const Duration throttle = Duration(milliseconds: 300);

  // Durées pour les requêtes réseau
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration apiTimeoutShort = Duration(seconds: 10);
  static const Duration apiTimeoutLong = Duration(seconds: 60);

  // Durées pour les refreshs
  static const Duration autoRefresh = Duration(minutes: 5);
  static const Duration cacheExpiry = Duration(hours: 1);
}
