import 'package:intl/intl.dart';

/// Le séparateur de milliers suit `Intl.defaultLocale`, donc la langue de
/// l'application : « 25 000 F CFA » en français, « 25,000 F CFA » en anglais.
/// L'unité, elle, reste la même : c'est le nom de la monnaie.
class CurrencyFormatter {
  static String format(double value) {
    return "${NumberFormat('#,###').format(value)} F CFA";
  }

  static String fcfa(num value) {
    return "${NumberFormat('#,###').format(value)} Fcfa";
  }

  /// Suffixe abrégé, pour les surfaces où la place manque — un montant en
  /// gros corps sur une carte, où « F CFA » déborderait la ligne.
  static String short(num value) {
    return "${NumberFormat('#,###').format(value)} F";
  }
}
