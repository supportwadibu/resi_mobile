import 'package:intl/intl.dart';

/// Formats de date de l'application, en mois abrégé : « 14 nov. 2026 ».
///
/// Le nom complet du mois (« septembre 2026 ») déborde les lignes des cartes
/// et des listes ; l'abrégé garde l'année sans prendre la place. Comme
/// [CurrencyFormatter], tout suit `Intl.defaultLocale`, donc la langue active.
class DateFormatter {
  /// « 14 nov. 2026 ».
  static String date(DateTime value) => DateFormat('d MMM y').format(value);

  /// « nov. 2026 ».
  static String monthYear(DateTime value) => DateFormat('MMM y').format(value);

  /// « 14 nov. 2026, 14h42 ».
  static String dateTime(DateTime value) =>
      '${date(value)}, ${time(value)}';

  /// « 14h42 » en français, « 14:42 » ailleurs : la notation en « h » est
  /// propre au français, un lecteur anglophone attend les deux-points.
  static String time(DateTime value) {
    final french = Intl.getCurrentLocale().startsWith('fr');
    return DateFormat(french ? "HH'h'mm" : 'HH:mm').format(value);
  }

  /// Instant d'une réservation, à l'heure du téléphone : « 14 nov. 2026, 14h42 ».
  ///
  /// Les instants arrivent de l'API en UTC ; la Côte d'Ivoire y est toute
  /// l'année, mais un téléphone réglé sur un autre fuseau doit lire son heure.
  static String stayInstant(DateTime value) => dateTime(value.toLocal());

  /// Période d'un séjour : « 14 nov. 2026, 14h42 → 15 nov. 2026, 12h30 ».
  ///
  /// Espaces insécables à l'intérieur de chaque date : sur une ligne trop
  /// étroite, le texte passe à la ligne après la flèche, jamais au milieu
  /// d'une date.
  static String stayPeriod(DateTime start, DateTime end) =>
      '${_unbreakable(stayInstant(start))} → ${_unbreakable(stayInstant(end))}';

  static String _unbreakable(String text) => text.replaceAll(' ', ' ');
}
