import 'reservation_model.dart';

/// Refus d'un chiffrage local, par le même code que le serveur.
class EarlyCheckOutRefusal implements Exception {
  const EarlyCheckOutRefusal(this.code);

  /// `invalid_departure`, `departure_in_future` ou `not_early_departure`.
  final String code;
}

/// Chiffrage d'un départ anticipé.
///
/// En ligne, le serveur le calcule et le mobile l'affiche : le propriétaire ne
/// retouche que le montant retenu. Hors ligne, [EarlyCheckOutQuote.estimate]
/// reprend la même règle, et le montant retenu part explicitement à la
/// synchronisation — le serveur n'en recalcule donc pas un autre.
class EarlyCheckOutQuote {
  const EarlyCheckOutQuote({
    required this.actualCheckOutAt,
    required this.plannedCheckOutAt,
    required this.plannedDays,
    required this.billedDays,
    required this.paidAmount,
    required this.proposedAmount,
    required this.refundAmount,
  });

  final DateTime actualCheckOutAt;
  final DateTime plannedCheckOutAt;
  final int plannedDays;
  final int billedDays;

  /// Montant réglé : plafond du montant retenu.
  final double paidAmount;

  /// Prorata proposé, retouchable par le propriétaire.
  final double proposedAmount;
  final double refundAmount;

  /// Remboursement qu'entraînerait [finalAmount], jamais négatif.
  double refundFor(double finalAmount) =>
      (paidAmount - finalAmount).clamp(0, double.infinity);

  /// Marge tolérée sur une sortie datée « dans le futur », comme au serveur :
  /// l'horloge du téléphone peut avancer de quelques minutes.
  static const clockSkewTolerance = Duration(minutes: 5);

  /// Chiffre un départ anticipé sur l'appareil, sans réseau.
  ///
  /// Reprend `quoteEarlyCheckOut` du serveur
  /// (`api/app/features/bookings/early_check_out.ts`) : tout jour entamé reste
  /// dû, le prorata porte sur le montant réglé, une demi-journée ou un
  /// passage est indivisible. Une évolution de la règle là-bas se reporte ici.
  factory EarlyCheckOutQuote.estimate(
    ReservationModel booking,
    DateTime departure, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final checkIn = booking.checkInAt;
    final plannedCheckOut = booking.checkOutAt;

    if (!departure.isAfter(checkIn)) {
      throw const EarlyCheckOutRefusal('invalid_departure');
    }
    if (departure.isAfter(clock.add(clockSkewTolerance))) {
      throw const EarlyCheckOutRefusal('departure_in_future');
    }
    if (!departure.isBefore(plannedCheckOut)) {
      throw const EarlyCheckOutRefusal('not_early_departure');
    }

    // `days_count` absent ou nul : repli sur la période facturée, pour ne
    // jamais diviser par zéro.
    final plannedDays = booking.daysCount > 0
        ? booking.daysCount
        : _maxOne(_countStayDays(checkIn, plannedCheckOut));

    final paid = booking.receivedAmount;
    final isFullDay = booking.stayType == StayType.fullDay;

    final billedDays = isFullDay
        ? _maxOne(_countStayDays(checkIn, departure)).clamp(1, plannedDays)
        : plannedDays;
    final proposed = isFullDay
        ? (paid * billedDays / plannedDays).roundToDouble()
        : paid;

    return EarlyCheckOutQuote(
      actualCheckOutAt: departure,
      plannedCheckOutAt: plannedCheckOut,
      plannedDays: plannedDays,
      billedDays: billedDays,
      paidAmount: paid,
      proposedAmount: proposed,
      refundAmount: paid - proposed,
    );
  }

  /// Jours entamés entre deux instants, comme `countStayDays` du serveur.
  static int _countStayDays(DateTime start, DateTime end) =>
      (end.difference(start).inMilliseconds / Duration.millisecondsPerDay)
          .ceil();

  static int _maxOne(int days) => days < 1 ? 1 : days;

  factory EarlyCheckOutQuote.fromJson(Map<String, dynamic> json) {
    return EarlyCheckOutQuote(
      actualCheckOutAt:
          DateTime.tryParse(json['actual_check_out_at'] as String? ?? '') ??
          DateTime.now(),
      plannedCheckOutAt:
          DateTime.tryParse(json['planned_check_out_at'] as String? ?? '') ??
          DateTime.now(),
      plannedDays: (json['planned_days'] as num?)?.toInt() ?? 0,
      billedDays: (json['billed_days'] as num?)?.toInt() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      proposedAmount: (json['proposed_amount'] as num?)?.toDouble() ?? 0,
      refundAmount: (json['refund_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
