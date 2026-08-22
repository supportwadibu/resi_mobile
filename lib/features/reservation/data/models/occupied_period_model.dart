import 'reservation_model.dart';

/// Période pendant laquelle un bien est immobilisé.
///
/// Sert à barrer les dates au calendrier de saisie : sans cette lecture, le
/// propriétaire ne découvrirait le conflit qu'au refus de la réservation,
/// après avoir tout saisi.
class OccupiedPeriodModel {
  const OccupiedPeriodModel({
    required this.bookingId,
    required this.checkInAt,
    required this.checkOutAt,
    required this.status,
    this.clientName,
  });

  final String bookingId;
  final DateTime checkInAt;
  final DateTime checkOutAt;
  final ReservationStatus status;

  /// Absent des réservations en ligne, dont le client n'est pas au carnet.
  final String? clientName;

  factory OccupiedPeriodModel.fromJson(Map<String, dynamic> json) {
    final checkIn = _date(json['check_in_at']) ?? DateTime.now();
    return OccupiedPeriodModel(
      bookingId: json['booking_id'] as String? ?? '',
      checkInAt: checkIn,
      // Une sortie illisible vaut l'entrée : la période est alors vide et ne
      // barre rien, plutôt que de bloquer le calendrier sur une date fausse.
      checkOutAt: _date(json['check_out_at']) ?? checkIn,
      status: ReservationStatus.fromCode(json['status'] as String?),
      clientName: json['client_name'] as String?,
    );
  }

  /// La période demandée empiète-t-elle sur celle-ci ?
  ///
  /// Bornes strictes, comme le serveur : une sortie à 12h et une entrée à 12h
  /// le même jour ne se chevauchent pas, ce qui permet d'enchaîner deux
  /// séjours dans la même journée.
  bool overlaps(DateTime start, DateTime end) =>
      start.isBefore(checkOutAt) && end.isAfter(checkInAt);

  @override
  String toString() =>
      'OccupiedPeriodModel($bookingId, $checkInAt → $checkOutAt)';
}

/// Les dates arrivent en ISO 8601 ; une valeur illisible vaut `null` plutôt
/// qu'une exception au milieu du décodage d'une liste.
DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
