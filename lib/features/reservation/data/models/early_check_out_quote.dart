import 'reservation_model.dart';

/// Options de facturation pour un départ anticipé.
enum EarlyCheckOutOption {
  prorata('prorata'),
  withPenalty('with_penalty'),
  fullAmount('full_amount');

  const EarlyCheckOutOption(this.value);
  final String value;

  static EarlyCheckOutOption fromString(String value) {
    switch (value) {
      case 'prorata':
        return prorata;
      case 'with_penalty':
        return withPenalty;
      case 'full_amount':
        return fullAmount;
      default:
        return prorata;
    }
  }
}

/// Détails d'une option de facturation spécifique.
class EarlyCheckOutOptionDetails {
  const EarlyCheckOutOptionDetails({
    required this.amount,
    required this.refund,
    this.penalty,
  });

  final double amount;
  final double refund;
  final double? penalty;

  factory EarlyCheckOutOptionDetails.fromJson(Map<String, dynamic> json) {
    return EarlyCheckOutOptionDetails(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      refund: (json['refund'] as num?)?.toDouble() ?? 0,
      penalty: (json['penalty'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'refund': refund,
      if (penalty != null) 'penalty': penalty,
    };
  }
}

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
    required this.options,
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

  /// Options de facturation disponibles avec leurs montants calculés.
  final Map<EarlyCheckOutOption, EarlyCheckOutOptionDetails> options;

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

    // Calcul des 3 options de facturation
    final prorataAmount = proposed;
    final prorataRefund = paid - prorataAmount;

    // Option avec pénalité (10% du montant payé par défaut)
    final defaultPenalty = (paid * 0.1).roundToDouble();
    final withPenaltyAmount = prorataAmount + defaultPenalty;
    final withPenaltyRefund = paid - withPenaltyAmount;

    // Option montant total (aucun remboursement)
    final fullAmount = paid;
    final fullRefund = 0.0;

    final options = {
      EarlyCheckOutOption.prorata: EarlyCheckOutOptionDetails(
        amount: prorataAmount,
        refund: prorataRefund,
      ),
      EarlyCheckOutOption.withPenalty: EarlyCheckOutOptionDetails(
        amount: withPenaltyAmount,
        refund: withPenaltyRefund,
        penalty: defaultPenalty,
      ),
      EarlyCheckOutOption.fullAmount: EarlyCheckOutOptionDetails(
        amount: fullAmount,
        refund: fullRefund,
      ),
    };

    return EarlyCheckOutQuote(
      actualCheckOutAt: departure,
      plannedCheckOutAt: plannedCheckOut,
      plannedDays: plannedDays,
      billedDays: billedDays,
      paidAmount: paid,
      proposedAmount: proposed,
      refundAmount: paid - proposed,
      options: options,
    );
  }

  /// Jours entamés entre deux instants, comme `countStayDays` du serveur.
  static int _countStayDays(DateTime start, DateTime end) =>
      (end.difference(start).inMilliseconds / Duration.millisecondsPerDay)
          .ceil();

  static int _maxOne(int days) => days < 1 ? 1 : days;

  factory EarlyCheckOutQuote.fromJson(Map<String, dynamic> json) {
    final optionsData = json['options'] as Map<String, dynamic>? ?? {};
    final options = <EarlyCheckOutOption, EarlyCheckOutOptionDetails>{};

    if (optionsData.containsKey('prorata')) {
      options[EarlyCheckOutOption.prorata] =
          EarlyCheckOutOptionDetails.fromJson(
            optionsData['prorata'] as Map<String, dynamic>,
          );
    }
    if (optionsData.containsKey('with_penalty')) {
      options[EarlyCheckOutOption.withPenalty] =
          EarlyCheckOutOptionDetails.fromJson(
            optionsData['with_penalty'] as Map<String, dynamic>,
          );
    }
    if (optionsData.containsKey('full_amount')) {
      options[EarlyCheckOutOption.fullAmount] =
          EarlyCheckOutOptionDetails.fromJson(
            optionsData['full_amount'] as Map<String, dynamic>,
          );
    }

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
      options: options,
    );
  }
}
