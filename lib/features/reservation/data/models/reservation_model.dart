/// Statut d'une réservation, aligné sur `BookingStatus` du serveur.
enum ReservationStatus {
  confirmed('confirmed', 'Confirmée'),
  inProgress('in_progress', 'En cours'),
  cancelled('cancelled', 'Annulée'),
  completed('completed', 'Terminée');

  const ReservationStatus(this.code, this.label);

  final String code;
  final String label;

  static ReservationStatus fromCode(String? code) {
    for (final status in ReservationStatus.values) {
      if (status.code == code) return status;
    }
    // Un statut inconnu vaut mieux affiché comme confirmé que faire échouer
    // la lecture de toute la liste.
    return ReservationStatus.confirmed;
  }

  /// Le séjour immobilise le bien : ni annulé, ni terminé.
  bool get isActive =>
      this == ReservationStatus.confirmed || this == ReservationStatus.inProgress;
}

/// Type de séjour, aligné sur `STAY_TYPES` du serveur.
///
/// Le passage et la demi-journée sont infra-journaliers : ils n'existent que
/// pour les réservations prises au comptoir, où un client peut n'occuper le
/// bien que quelques heures.
enum StayType {
  passage('passage', 'Passage'),
  halfDay('half_day', 'Demi-journée'),
  fullDay('full_day', 'Journée complète');

  const StayType(this.code, this.label);

  final String code;
  final String label;

  static StayType fromCode(String? code) {
    for (final type in StayType.values) {
      if (type.code == code) return type;
    }
    return StayType.fullDay;
  }

  /// Durée par défaut proposée à l'ouverture du formulaire.
  ///
  /// Reprend la règle du serveur : une journée court de 12h à 12h le
  /// lendemain, une demi-journée vaut 12 h, et un passage 4 h — le
  /// propriétaire ajustant l'heure de sortie réelle.
  Duration get defaultDuration => switch (this) {
    StayType.fullDay => const Duration(hours: 24),
    StayType.halfDay => const Duration(hours: 12),
    StayType.passage => const Duration(hours: 4),
  };
}

/// Canal de vente d'une réservation.
///
/// `offline` désigne une réservation prise au comptoir, par opposition à
/// `online` prise par un client depuis l'application. Ne change jamais : à ne
/// pas confondre avec l'état de synchronisation d'une saisie hors réseau.
enum ReservationSource {
  online('online', 'En ligne'),
  offline('offline', 'Comptoir');

  const ReservationSource(this.code, this.label);

  final String code;
  final String label;

  static ReservationSource fromCode(String? code) =>
      code == 'offline' ? ReservationSource.offline : ReservationSource.online;
}

/// Résumé du client, joint par le serveur aux réservations comptoir.
class ReservationClient {
  const ReservationClient({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  final String id;
  final String fullName;
  final String phone;

  factory ReservationClient.fromJson(Map<String, dynamic> json) {
    return ReservationClient(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

/// Résumé du bien réservé, joint par le serveur à la liste.
class ReservationProperty {
  const ReservationProperty({
    required this.id,
    required this.title,
    required this.city,
    this.image,
  });

  final String id;
  final String title;
  final String city;
  final String? image;

  factory ReservationProperty.fromJson(Map<String, dynamic> json) {
    return ReservationProperty(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      city: json['city'] as String? ?? '',
      image: json['image'] as String?,
    );
  }
}

/// Réservation telle que servie par `GET /proprio/bookings`.
class ReservationModel {
  const ReservationModel({
    required this.id,
    required this.propertyId,
    this.property,
    required this.clientId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    required this.totalAmount,
    this.dailyPrice = 0,
    this.durationDiscountPercent = 0,
    this.discountAmount = 0,
    this.message,
    this.source = ReservationSource.online,
    this.stayType = StayType.fullDay,
    this.client,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    this.expectedAmount = 0,
    this.receivedAmount = 0,
    this.depositAmount = 0,
  }) : _checkInAt = checkInAt,
       _checkOutAt = checkOutAt;

  final String id;
  final String propertyId;

  /// `null` si le bien a été supprimé depuis la réservation.
  final ReservationProperty? property;
  final String clientId;
  final ReservationStatus status;
  final DateTime startDate;
  final DateTime endDate;
  /// Jours d'occupation facturés (12h → 12h le lendemain = 1 jour).
  final int daysCount;
  final double totalAmount;
  final double dailyPrice;

  /// Remise de durée appliquée, en pourcentage. `0` hors palier.
  final int durationDiscountPercent;

  /// Remise d'un code promo, en montant.
  final double discountAmount;
  final String? message;

  /// Canal de vente : comptoir ou en ligne.
  final ReservationSource source;
  final StayType stayType;

  /// Client du carnet, présent sur les réservations comptoir.
  ///
  /// Figé à la réservation par le serveur : une fiche renommée ou archivée ne
  /// doit pas réécrire l'historique.
  final ReservationClient? client;

  /// Entrée et sortie à l'heure près.
  ///
  /// Doublent `startDate` / `endDate`, que les réservations en ligne sont
  /// seules à porter. Les accesseurs publics retombent sur ces dernières.
  final DateTime? _checkInAt;
  final DateTime? _checkOutAt;

  /// Montant calculé depuis la grille du bien, avant négociation.
  final double expectedAmount;

  /// Montant réellement convenu avec le client, saisi par le propriétaire.
  final double receivedAmount;

  /// Acompte versé à la réservation.
  final double depositAmount;

  /// Heure d'entrée, ou la date de début pour une réservation en ligne.
  DateTime get checkInAt => _checkInAt ?? startDate;

  /// Heure de sortie, ou la date de fin pour une réservation en ligne.
  DateTime get checkOutAt => _checkOutAt ?? endDate;

  /// Reste dû après l'acompte, jamais négatif.
  double get balanceDue =>
      (receivedAmount - depositAmount).clamp(0, double.infinity);

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String,
      propertyId: json['property_id'] as String? ?? '',
      property: json['property'] is Map<String, dynamic>
          ? ReservationProperty.fromJson(json['property'] as Map<String, dynamic>)
          : null,
      clientId: json['client_id'] as String? ?? '',
      status: ReservationStatus.fromCode(json['status'] as String?),
      startDate: _date(json['start_date']) ?? DateTime.now(),
      endDate: _date(json['end_date']) ?? DateTime.now(),
      // `nights_count` : nom porté par les réservations antérieures au passage
      // à une facturation en jours d'occupation.
      daysCount:
          (json['days_count'] as num?)?.toInt() ??
          (json['nights_count'] as num?)?.toInt() ??
          0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      dailyPrice: (json['daily_price'] as num?)?.toDouble() ?? 0,
      durationDiscountPercent:
          (json['duration_discount_percent'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      message: json['message'] as String?,
      // Champs propres aux réservations comptoir. Les réservations
      // enregistrées avant leur introduction ne les portent pas : chaque
      // repli ramène au comportement d'origine.
      source: ReservationSource.fromCode(json['source'] as String?),
      stayType: StayType.fromCode(json['stay_type'] as String?),
      client: json['client'] is Map<String, dynamic>
          ? ReservationClient.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      checkInAt: _date(json['check_in_at']),
      checkOutAt: _date(json['check_out_at']),
      expectedAmount:
          (json['expected_amount'] as num?)?.toDouble() ??
          (json['total_amount'] as num?)?.toDouble() ??
          0,
      receivedAmount:
          (json['received_amount'] as num?)?.toDouble() ??
          (json['total_amount'] as num?)?.toDouble() ??
          0,
      depositAmount: (json['deposit_amount'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Les dates arrivent en ISO 8601 ; une valeur illisible vaut `null`
  /// plutôt qu'une exception au milieu du décodage d'une liste.
  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  /// Durée du séjour, dans l'unité facturée.
  ///
  /// Un passage ou une demi-journée s'affiche par son type : il compte pour un
  /// jour facturé, et l'annoncer « 1 jour » démentirait la durée réellement
  /// vendue. Traduire les séjours longs en semaines ou en mois masquerait de
  /// même la durée exacte sur laquelle le montant a été calculé.
  String get durationLabel => switch (stayType) {
    StayType.passage || StayType.halfDay => stayType.label,
    StayType.fullDay => daysCount > 1 ? '$daysCount jours' : '1 jour',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReservationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ReservationModel(id: $id, status: ${status.code})';
}
