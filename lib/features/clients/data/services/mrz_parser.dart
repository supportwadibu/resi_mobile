import '../models/client_model.dart';

/// Ce que la bande MRZ d'une pièce d'identité permet de préremplir.
class MrzResult {
  const MrzResult({
    required this.documentType,
    required this.surname,
    required this.givenNames,
    this.documentNumber,
    this.nationality,
    this.birthDate,
  });

  final ClientIdDocumentType documentType;
  final String surname;
  final String givenNames;

  /// `null` si son chiffre de contrôle ne correspond pas : un numéro mal lu
  /// ne doit pas entrer au carnet comme s'il était sûr.
  final String? documentNumber;
  final String? nationality;
  final DateTime? birthDate;

  /// Nom complet dans l'ordre d'usage : prénoms puis nom.
  String get fullName =>
      [givenNames, surname].where((part) => part.isNotEmpty).join(' ');
}

/// Lecture de la zone MRZ (ICAO 9303) d'une pièce d'identité.
///
/// La MRZ est normalisée : même alphabet, mêmes positions, chiffres de
/// contrôle — ce qui la rend fiable là où la lecture du recto dépendrait de la
/// mise en page de chaque pièce. Deux formats couvrent les pièces présentées
/// au comptoir :
///
/// - TD1, trois lignes de 30 caractères : la CNI ivoirienne biométrique et la
///   plupart des cartes d'identité ;
/// - TD3, deux lignes de 44 : les passeports.
///
/// Fonction pure, sans ML Kit : elle reçoit le texte reconnu et s'éprouve sans
/// appareil photo.
abstract final class MrzParser {
  static final _mrzChars = RegExp(r'^[A-Z0-9<]+$');

  /// `null` si aucune MRZ exploitable n'est trouvée dans [text].
  static MrzResult? parse(String text) {
    final lines = text
        .split('\n')
        .map(_normalize)
        .where((line) => line.length >= 28 && _mrzChars.hasMatch(line))
        .toList(growable: false);

    return _parseTd3(lines) ?? _parseTd1(lines);
  }

  /// Ramène une ligne OCR à l'alphabet MRZ.
  ///
  /// Les chevrons sont souvent lus « « » ou espacés, et les espaces n'existent
  /// pas en MRZ : ils sont retirés plutôt que remplacés, pour ne pas décaler
  /// les positions.
  static String _normalize(String line) => line
      .toUpperCase()
      .replaceAll('«', '<')
      .replaceAll('‹', '<')
      .replaceAll(RegExp(r'\s'), '');

  static MrzResult? _parseTd3(List<String> lines) {
    for (var i = 0; i < lines.length - 1; i++) {
      final first = _fit(lines[i], 44);
      final second = _fit(lines[i + 1], 44);
      if (first == null || second == null || !first.startsWith('P')) continue;

      final names = _names(first.substring(5));
      if (names == null) continue;

      final number = second.substring(0, 9);
      return MrzResult(
        documentType: ClientIdDocumentType.passeport,
        surname: names.$1,
        givenNames: names.$2,
        documentNumber: _checked(number, second[9]),
        nationality: _field(second.substring(10, 13)),
        birthDate: _date(second.substring(13, 19), second[19]),
      );
    }
    return null;
  }

  static MrzResult? _parseTd1(List<String> lines) {
    for (var i = 0; i < lines.length - 2; i++) {
      final first = _fit(lines[i], 30);
      final second = _fit(lines[i + 1], 30);
      final third = _fit(lines[i + 2], 30);
      if (first == null || second == null || third == null) continue;
      if (!first.startsWith('I') &&
          !first.startsWith('A') &&
          !first.startsWith('C')) {
        continue;
      }

      final names = _names(third);
      if (names == null) continue;

      return MrzResult(
        documentType: ClientIdDocumentType.cni,
        surname: names.$1,
        givenNames: names.$2,
        documentNumber: _td1DocumentNumber(first),
        nationality: _field(second.substring(15, 18)),
        birthDate: _date(second.substring(0, 6), second[6]),
      );
    }
    return null;
  }

  /// Numéro d'une carte TD1, éventuellement long.
  ///
  /// Au-delà de 9 caractères, ICAO place `<` à la position du chiffre de
  /// contrôle et reporte la suite du numéro — et son contrôle — en tête des
  /// données optionnelles. C'est le cas de numéros de CNI plus longs que le
  /// champ.
  static String? _td1DocumentNumber(String first) {
    final head = first.substring(5, 14);
    final check = first[14];
    if (check != '<') return _checked(head, check);

    final optional = first.substring(15);
    final end = optional.indexOf('<');
    final tail = end == -1 ? optional : optional.substring(0, end);
    if (tail.length < 2) return null;

    final number = head + tail.substring(0, tail.length - 1);
    return _checked(number, tail[tail.length - 1]);
  }

  /// Complète ou tronque une ligne à la longueur attendue.
  ///
  /// L'OCR perd souvent un chevron de fin, jamais un caractère utile : un
  /// écart d'un ou deux caractères en fin de ligne se rattrape. Au-delà, la
  /// ligne n'est pas du format cherché.
  static String? _fit(String line, int length) {
    if ((line.length - length).abs() > 2) return null;
    if (line.length >= length) return line.substring(0, length);
    return line.padRight(length, '<');
  }

  /// `NOM<<PRENOM<AUTRE` → (`NOM`, `PRENOM AUTRE`). `null` sans nom.
  static (String, String)? _names(String field) {
    final trimmed = field.replaceFirst(RegExp(r'<+$'), '');
    final parts = trimmed.split('<<');
    final surname = parts.first.replaceAll('<', ' ').trim();
    if (surname.isEmpty || RegExp(r'\d').hasMatch(surname)) return null;

    final given = parts.length > 1
        ? parts.sublist(1).join(' ').replaceAll('<', ' ').trim()
        : '';
    return (_title(surname), _title(given.replaceAll(RegExp(r'\s+'), ' ')));
  }

  /// `KOUASSI` → `Kouassi` : la MRZ est en capitales, le carnet ne l'est pas.
  static String _title(String value) => value
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0] + word.substring(1).toLowerCase())
      .join(' ');

  static String? _field(String value) {
    final cleaned = value.replaceAll('<', '');
    return cleaned.isEmpty ? null : cleaned;
  }

  /// Valeur retenue seulement si son chiffre de contrôle correspond.
  static String? _checked(String value, String check) {
    if (checkDigit(value) != check) return null;
    final cleaned = value.replaceAll('<', '');
    return cleaned.isEmpty ? null : cleaned;
  }

  /// Date `AAMMJJ`, vérifiée. Le siècle est déduit : une date de naissance
  /// ne peut pas être future.
  static DateTime? _date(String value, String check) {
    if (checkDigit(value) != check) return null;
    final yy = int.tryParse(value.substring(0, 2));
    final mm = int.tryParse(value.substring(2, 4));
    final dd = int.tryParse(value.substring(4, 6));
    if (yy == null || mm == null || dd == null) return null;
    if (mm < 1 || mm > 12 || dd < 1 || dd > 31) return null;

    final currentYY = DateTime.now().year % 100;
    final year = yy > currentYY ? 1900 + yy : 2000 + yy;
    return DateTime(year, mm, dd);
  }

  /// Chiffre de contrôle ICAO : pondérations 7, 3, 1 ; chiffres à leur
  /// valeur, lettres de A=10 à Z=35, chevron à 0.
  static String checkDigit(String value) {
    const weights = [7, 3, 1];
    var sum = 0;
    for (var i = 0; i < value.length; i++) {
      final code = value.codeUnitAt(i);
      final int digit;
      if (code >= 48 && code <= 57) {
        digit = code - 48;
      } else if (code >= 65 && code <= 90) {
        digit = code - 55;
      } else {
        digit = 0;
      }
      sum += digit * weights[i % 3];
    }
    return '${sum % 10}';
  }
}
