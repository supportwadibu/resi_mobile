import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class PhoneHelper {
  PhoneHelper._();

  static IsoCode? isoCodeOf(String iso2) =>
      IsoCode.values.where((c) => c.name == iso2.toUpperCase()).firstOrNull;

  static PhoneNumber? tryParse(String input, String iso2) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final isoCode = isoCodeOf(iso2);
    if (isoCode == null) return null;

    try {
      final parsed = PhoneNumber.parse(trimmed, callerCountry: isoCode);
      return parsed.nsn.isEmpty ? null : parsed;
    } on Exception {
      return null;
    }
  }

  static bool isValid(String input, String iso2) =>
      tryParse(input, iso2)?.isValid() ?? false;

  static String? toE164(String input, String iso2) {
    final parsed = tryParse(input, iso2);
    if (parsed == null || !parsed.isValid()) return null;
    return parsed.international;
  }

  static String toNational(String? e164, String iso2) {
    final raw = e164?.trim() ?? '';
    if (raw.isEmpty) return '';

    final parsed = tryParse(raw, iso2);
    if (parsed == null) return raw;

    return parsed.formatNsn();
  }

  static String? validate(String? input, String iso2) {
    if (input == null || input.trim().isEmpty) return 'Ce champ est requis';
    if (isoCodeOf(iso2) == null) return null;
    if (!isValid(input, iso2)) return 'Numéro invalide pour ce pays';
    return null;
  }

  static String hintFor(String iso2) => switch (isoCodeOf(iso2)) {
    IsoCode.CI => '07 00 00 00 00',
    _ => 'Numéro sans indicatif',
  };
}
