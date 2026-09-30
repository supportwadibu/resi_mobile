/// Identité exigée par le registre de police : état civil, domicile et date
/// de délivrance de la pièce.
///
/// Données de la personne, pas du séjour : elles vivent sur la fiche du
/// carnet et se complètent à tout moment, au comptoir comme après coup. Tous
/// les champs sont facultatifs — une fiche antérieure n'en porte aucun.
class ClientIdentity {
  const ClientIdentity({
    this.birthDate,
    this.birthPlace,
    this.nationality,
    this.address,
    this.idDocumentIssuedAt,
  });

  /// Dates calendaires, sans heure : une date de naissance n'a pas de fuseau.
  final DateTime? birthDate;
  final String? birthPlace;

  /// Texte libre, tel qu'il s'écrit sur le registre : « Ivoirienne ».
  final String? nationality;

  /// Domicile habituel.
  final String? address;
  final DateTime? idDocumentIssuedAt;

  static const empty = ClientIdentity();

  factory ClientIdentity.fromJson(Map<String, dynamic> json) {
    return ClientIdentity(
      birthDate: _calendarDate(json['birth_date']),
      birthPlace: _text(json['birth_place']),
      nationality: _text(json['nationality']),
      address: _text(json['address']),
      idDocumentIssuedAt: _calendarDate(json['id_document_issued_at']),
    );
  }

  /// Champs du formulaire `multipart` : dates en `AAAA-MM-JJ`.
  ///
  /// Un champ vide part en chaîne vide quand [includeEmpty] — c'est ainsi
  /// qu'une mise à jour efface une valeur, le serveur lisant `''` comme
  /// `null`. À la création, rien à effacer : les champs vides sont omis.
  Map<String, String> toFormFields({bool includeEmpty = false}) {
    final fields = <String, String?>{
      'birth_date': _formatDay(birthDate),
      'birth_place': birthPlace?.trim(),
      'nationality': nationality?.trim(),
      'address': address?.trim(),
      'id_document_issued_at': _formatDay(idDocumentIssuedAt),
    };

    return {
      for (final entry in fields.entries)
        if (entry.value != null && entry.value!.isNotEmpty)
          entry.key: entry.value!
        else if (includeEmpty)
          entry.key: '',
    };
  }

  /// Toutes les colonnes du registre sont-elles renseignées ?
  bool get isComplete =>
      birthDate != null &&
      _filled(birthPlace) &&
      _filled(nationality) &&
      _filled(address) &&
      idDocumentIssuedAt != null;

  ClientIdentity copyWith({
    DateTime? birthDate,
    bool clearBirthDate = false,
    String? birthPlace,
    String? nationality,
    String? address,
    DateTime? idDocumentIssuedAt,
    bool clearIdDocumentIssuedAt = false,
  }) {
    return ClientIdentity(
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      birthPlace: birthPlace ?? this.birthPlace,
      nationality: nationality ?? this.nationality,
      address: address ?? this.address,
      idDocumentIssuedAt: clearIdDocumentIssuedAt
          ? null
          : (idDocumentIssuedAt ?? this.idDocumentIssuedAt),
    );
  }

  static bool _filled(String? value) => value != null && value.trim().isNotEmpty;

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  /// Le serveur sérialise une date en instant UTC (`1990-04-12T00:00:00Z`) :
  /// seule sa partie calendaire compte, lue en UTC pour ne pas glisser d'un
  /// jour sur un appareil réglé à l'ouest de Greenwich.
  static DateTime? _calendarDate(Object? value) {
    if (value is! String) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    final utc = parsed.toUtc();
    return DateTime(utc.year, utc.month, utc.day);
  }

  static String? _formatDay(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
