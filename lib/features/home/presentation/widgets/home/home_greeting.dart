import 'package:easy_localization/easy_localization.dart';
import 'dart:math';

/// Mots d'accueil de l'en-tête : la salutation suit l'heure, et un tirage
/// parmi plusieurs formules évite que l'écran répète chaque jour la même.
abstract final class HomeGreeting {
  /// Valables à toute heure, mêlées à celles du moment. « Bonne arrivée » et
  /// « Akwaba » sont les mots d'accueil d'Abidjan : l'application parle comme
  /// ses utilisateurs.
  ///
  /// Les listes portent des clés de traduction : le tirage se fait sur la
  /// formule, la langue est appliquée au moment de l'afficher.
  static const anytime = [
    'greeting.hi',
    'greeting.good_to_see_you',
    'greeting.bonne_arrivee',
    'greeting.akwaba',
  ];

  static const morning = [
    'greeting.good_morning',
    'greeting.nice_morning',
    'greeting.slept_well',
  ];
  static const afternoon = [
    'greeting.hello',
    'greeting.good_afternoon',
    'greeting.lovely_afternoon',
  ];
  static const evening = [
    'greeting.good_evening',
    'greeting.nice_evening',
    'greeting.lovely_evening',
  ];
  static const night = [
    'greeting.good_night',
    'greeting.up_late',
    'greeting.still_on_deck',
  ];

  /// À la place du nom quand aucun n'est connu — session ouverte avant qu'on
  /// ne le conserve, et API injoignable. Sans référence à l'heure : la
  /// salutation au-dessus s'en charge déjà.
  static const taglines = [
    'greeting.tagline_residences',
    'greeting.tagline_full',
    'greeting.tagline_running',
  ];

  /// Formules propres à l'heure [hour]. La nuit commence à 23 h et s'achève à 5 h :
  /// un comptoir peut recevoir un client tard, et « Bonjour » à 4 h sonnerait
  /// faux.
  static List<String> forHour(int hour) => switch (hour) {
    >= 5 && < 12 => morning,
    >= 12 && < 18 => afternoon,
    >= 18 && < 23 => evening,
    _ => night,
  };

  static String salutation(DateTime now, Random random) {
    final pool = [...forHour(now.hour), ...anytime];
    return pool[random.nextInt(pool.length)].tr();
  }

  static String tagline(Random random) =>
      taglines[random.nextInt(taglines.length)].tr();
}
