import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double value) {
    return "${NumberFormat("#,###", "fr_FR").format(value)} F CFA";
  }

  static String fcfa(num value) {
    return "${NumberFormat('#,###', 'fr_FR').format(value)} Fcfa";
  }
}
