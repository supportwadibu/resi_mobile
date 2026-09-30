/// Ce que les libellés imprimés d'une pièce permettent de lire.
class IdLabelFields {
  const IdLabelFields({
    this.surname,
    this.givenNames,
    this.documentNumber,
    this.birthDate,
    this.birthPlace,
    this.nationality,
    this.address,
    this.issuedAt,
  });

  final String? surname;
  final String? givenNames;
  final String? documentNumber;
  final DateTime? birthDate;
  final String? birthPlace;
  final String? nationality;
  final String? address;
  final DateTime? issuedAt;

  bool get isEmpty =>
      surname == null &&
      givenNames == null &&
      documentNumber == null &&
      birthDate == null &&
      birthPlace == null &&
      nationality == null &&
      address == null &&
      issuedAt == null;
}

enum _Field {
  surname,
  givenNames,
  documentNumber,
  birthDate,
  birthPlace,
  nationality,
  address,
  issuedAt,

  /// Libellés reconnus pour ne jamais être pris pour la valeur d'un autre :
  /// « Sexe » sous « Lieu de naissance » n'est pas un lieu.
  ignored,
}

/// Lecture des libellés imprimés d'une pièce d'identité — « Lieu de
/// naissance », « Date de délivrance », « Domicile »…
///
/// Complément de `MrzParser`, pas un substitut : la MRZ est normalisée et
/// vérifiée par chiffres de contrôle, les libellés varient d'une pièce et
/// d'une génération à l'autre. Mais la MRZ ne porte ni le lieu de naissance,
/// ni la date de délivrance, ni le domicile, que le registre de police exige.
/// La lecture est donc faite **au mieux** : un champ non trouvé reste vide, et
/// tout se corrige à la main.
///
/// Deux mises en page couvertes, celles que rend ML Kit :
///
/// - la valeur sur la ligne du libellé : `Domicile : COCODY` ;
/// - la valeur sous le libellé, bilingue ou non : `Nom / Surname` puis
///   `KOUASSI`.
///
/// Fonction pure, sans ML Kit : elle reçoit le texte reconnu et s'éprouve sans
/// appareil photo.
abstract final class IdLabelParser {
  /// Alias par champ, sans accent et en minuscules. L'ordre compte : un alias
  /// plus long passe avant celui qu'il contient (« prénom » avant « nom »).
  static const _aliases = <(_Field, List<String>)>[
    (_Field.givenNames, ['prenom(s)', 'prenoms', 'prenom', 'given names', 'given name']),
    (_Field.birthDate, ['date de naissance', 'date of birth', 'ne(e) le', 'nee le', 'ne le']),
    (_Field.birthPlace, ['lieu de naissance', 'place of birth']),
    (_Field.issuedAt, [
      'date de delivrance',
      "date d'emission",
      'date d emission',
      'date of issue',
      'delivree le',
      'delivre le',
      'emise le',
    ]),
    (_Field.ignored, [
      "date d'expiration",
      'date d expiration',
      'date of expiry',
      'expire le',
      'sexe',
      'sex',
      'taille',
      'height',
      'profession',
      'signature',
      'republique',
      'carte nationale',
      'nni',
    ]),
    (_Field.nationality, ['nationalite', 'nationality']),
    (_Field.address, ['domicile', 'adresse', 'address']),
    (_Field.documentNumber, ['numero de la carte', 'card number', 'numero', 'n°', 'no.']),
    (_Field.surname, ['nom', 'surname']),
  ];

  static IdLabelFields parse(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    final found = <_Field, String>{};

    for (var i = 0; i < lines.length; i++) {
      final match = _labelOf(lines[i]);
      if (match == null || match.$1 == _Field.ignored) continue;
      if (found.containsKey(match.$1)) continue;

      final (field, rest) = match;
      if (rest.isNotEmpty) {
        found[field] = rest;
      } else if (i + 1 < lines.length && _labelOf(lines[i + 1]) == null) {
        found[field] = lines[i + 1];
      }
    }

    return IdLabelFields(
      surname: _name(found[_Field.surname]),
      givenNames: _name(found[_Field.givenNames]),
      documentNumber: _documentNumber(found[_Field.documentNumber]),
      birthDate: _date(found[_Field.birthDate], past: true),
      birthPlace: _name(found[_Field.birthPlace]),
      nationality: _name(found[_Field.nationality]),
      address: _name(found[_Field.address]),
      issuedAt: _date(found[_Field.issuedAt], past: true),
    );
  }

  /// Champ désigné par le libellé en tête de [line], et ce qui le suit sur la
  /// même ligne. `null` si la ligne n'est pas un libellé.
  static (_Field, String)? _labelOf(String line) {
    final folded = _fold(line);

    for (final (field, aliases) in _aliases) {
      for (final alias in aliases) {
        if (!_startsWithWord(folded, alias)) continue;
        return (field, _rest(line, folded, alias.length, aliases));
      }
    }
    return null;
  }

  /// Le libellé doit être un mot entier : « nomade » n'est pas « nom ».
  static bool _startsWithWord(String folded, String alias) {
    if (!folded.startsWith(alias)) return false;
    if (folded.length == alias.length) return true;
    return !RegExp(r'[a-z0-9]').hasMatch(folded[alias.length]);
  }

  /// Ce qui suit le libellé, séparateurs et traduction retirés : `Nom /
  /// Surname : X` → `X`. Le texte replié garde les positions du texte
  /// d'origine, un caractère pour un caractère.
  static String _rest(
    String line,
    String folded,
    int start,
    List<String> aliases,
  ) {
    var index = start;
    var progressed = true;

    while (progressed) {
      progressed = false;
      while (index < folded.length && ' /:.-–|'.contains(folded[index])) {
        index++;
        progressed = true;
      }
      for (final alias in aliases) {
        if (folded.startsWith(alias, index)) {
          index += alias.length;
          progressed = true;
          break;
        }
      }
    }

    return line.substring(index).trim();
  }

  /// Minuscules sans accent, longueur conservée.
  static String _fold(String value) {
    const from = 'àâäáãèéêëìíîïòóôöõùúûüçñ’';
    const to = "aaaaaeeeeiiiiooooouuuucn'";
    final buffer = StringBuffer();
    for (final char in value.toLowerCase().split('')) {
      final index = from.indexOf(char);
      buffer.write(index == -1 ? char : to[index]);
    }
    return buffer.toString();
  }

  /// `KOUASSI AYA` → `Kouassi Aya` : les pièces impriment en capitales, le
  /// carnet non. Une valeur déjà en casse mixte est laissée telle quelle.
  static String? _name(String? value) {
    if (value == null) return null;
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty || !RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(cleaned)) {
      return null;
    }
    if (cleaned != cleaned.toUpperCase()) return cleaned;

    return cleaned
        .split(' ')
        .map((word) => word[0] + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Premier jeton alphanumérique assez long pour être un numéro de pièce.
  static String? _documentNumber(String? value) {
    if (value == null) return null;
    final match = RegExp(r'[A-Z0-9][A-Z0-9 ]{5,}[A-Z0-9]')
        .firstMatch(value.toUpperCase());
    if (match == null) return null;
    final number = match.group(0)!.replaceAll(' ', '');
    return RegExp(r'\d').hasMatch(number) ? number : null;
  }

  /// `12/04/1990`, `12.04.1990`, `12-04-90`. Une date impossible, ou future
  /// quand [past] l'interdit, vaut `null` : un champ vide se remarque, une
  /// date fausse non.
  static DateTime? _date(String? value, {required bool past}) {
    if (value == null) return null;
    final match = RegExp(r'(\d{1,2})\s*[/.\- ]\s*(\d{1,2})\s*[/.\- ]\s*(\d{2,4})')
        .firstMatch(value);
    if (match == null) return null;

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    var year = int.parse(match.group(3)!);
    if (year < 100) {
      final current = DateTime.now().year % 100;
      year += year > current ? 1900 : 2000;
    }

    final date = DateTime(year, month, day);
    // `DateTime` accepte le 45/13 en le reportant : la date relue doit
    // retomber sur les mêmes composantes.
    if (date.day != day || date.month != month || date.year != year) {
      return null;
    }
    if (past && date.isAfter(DateTime.now())) return null;
    return date;
  }
}
