import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double value) {
    return "${NumberFormat("#,###", "fr_FR").format(value)} F CFA";
  }

  static String fcfa(num value) {
    return "${NumberFormat('#,###', 'fr_FR').format(value)} Fcfa";
  }

  /// Suffixe abrégé, pour les surfaces où la place manque — un montant en
  /// gros corps sur une carte, où « F CFA » déborderait la ligne.
  static String short(num value) {
    return "${NumberFormat('#,###', 'fr_FR').format(value)} F";
  }
}
