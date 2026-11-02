/// Revenu du mois en cours rapporté au précédent.
class BookingRevenueStats {
  const BookingRevenueStats({
    required this.currentMonth,
    required this.previousMonth,
    this.growthPercent,
  });

  final double currentMonth;
  final double previousMonth;

  /// Variation d'un mois à l'autre, `null` quand le mois précédent est à zéro :
  /// une progression depuis rien n'a pas de valeur, et afficher « +100 % »
  /// laisserait croire à un doublement.
  final double? growthPercent;

  factory BookingRevenueStats.fromJson(Map<String, dynamic> json) {
    return BookingRevenueStats(
      currentMonth: (json['current_month'] as num?)?.toDouble() ?? 0,
      previousMonth: (json['previous_month'] as num?)?.toDouble() ?? 0,
      growthPercent: (json['growth_percent'] as num?)?.toDouble(),
    );
  }
}

/// Chiffres du tableau de bord des réservations, cadrés sur le mois en cours.
class BookingStatsModel {
  const BookingStatsModel({
    required this.tauxOccupation,
    required this.upcoming,
    required this.inProgress,
    required this.revenue,
  });

  /// Part des jours-bien occupés sur le mois, de 0 à 1.
  final double tauxOccupation;

  /// Séjours confirmés dont l'arrivée reste à venir.
  final int upcoming;

  /// Séjours en cours : le client est arrivé et n'a pas encore quitté.
  final int inProgress;

  final BookingRevenueStats revenue;

  /// Taux d'occupation en pourcentage entier, tel qu'affiché sur la tuile.
  int get occupancyPercent => (tauxOccupation * 100).round();

  factory BookingStatsModel.fromJson(Map<String, dynamic> json) {
    return BookingStatsModel(
      tauxOccupation: (json['taux_occupation'] as num?)?.toDouble() ?? 0,
      upcoming: (json['upcoming'] as num?)?.toInt() ?? 0,
      inProgress: (json['in_progress'] as num?)?.toInt() ?? 0,
      revenue: BookingRevenueStats.fromJson(
        json['revenue'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
