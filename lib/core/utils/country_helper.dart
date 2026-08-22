import 'package:country_picker/country_picker.dart';

/// Résolution d'un pays stocké, quelle que soit la forme reçue.
///
/// `Country.tryParse` n'accepte que le code ISO ou le libellé exact du paquet
/// (« Côte d'Ivoire »). Les dossiers déposés avant que le client ne stocke le
/// code ISO portent la forme anglaise (« Ivory Coast »), que `tryParse`
/// rejette : sans ce repli, leur pays disparaîtrait à la relecture.
class CountryHelper {
  CountryHelper._();

  /// Pays correspondant à [stored], ou `null` s'il reste introuvable.
  ///
  /// Accepte le code ISO2, le libellé localisé du paquet, et le nom anglais.
  static Country? resolve(String? stored) {
    final value = stored?.trim() ?? '';
    if (value.isEmpty) return null;

    final direct = Country.tryParse(value);
    if (direct != null) return direct;

    // Certains libellés d'usage n'existent nulle part dans les données du
    // paquet, qui ne connaît que la forme locale : « Ivory Coast » n'y figure
    // pas, seul « Côte d'Ivoire » est indexé. Ces alias couvrent les dossiers
    // enregistrés avant que le client ne stocke le code ISO2.
    final iso2 = _aliases[_normalize(value)];
    return iso2 == null ? null : Country.tryParse(iso2);
  }

  /// Libellés alternatifs vers leur code ISO2.
  ///
  /// À compléter au fil des pays réellement rencontrés en base : un alias
  /// inventé pour un pays jamais stocké n'apporte rien.
  static const Map<String, String> _aliases = {
    'ivorycoast': 'CI',
    'cotedivoire': 'CI',
  };

  /// Réduit un libellé à ses lettres, sans accents ni ponctuation.
  ///
  /// « Côte d'Ivoire », « Cote d Ivoire » et « cotedivoire » désignent le même
  /// pays : la comparaison ne doit pas achopper sur l'apostrophe ou l'accent.
  static String _normalize(String value) {
    const accents = 'àáâãäçèéêëìíîïñòóôõöùúûü';
    const plain = 'aaaaaceeeeiiiinooooouuuu';

    final buffer = StringBuffer();
    for (final char in value.toLowerCase().split('')) {
      final index = accents.indexOf(char);
      final normalized = index == -1 ? char : plain[index];
      if (RegExp(r'[a-z]').hasMatch(normalized)) buffer.write(normalized);
    }
    return buffer.toString();
  }

  /// Code ISO2 du pays stocké, ou `null`.
  static String? iso2Of(String? stored) => resolve(stored)?.countryCode;
}
