import '../../../stats/data/models/finance/revenue_point_model.dart';

/// Relevé du mois servi au gérant par `GET /gerant/finance/overview`.
///
/// Volontairement sans revenu net, et la forme se distingue pour cela du
/// `FinanceOverviewModel` du propriétaire : le net déduit des charges qui ne
/// relèvent pas du gérant — abonnement du propriétaire, charges communes de la
/// résidence, dépenses portées par d'autres logements. Calculé sur son seul
/// périmètre, il ne donnerait pas une marge partielle mais un chiffre faux, qui
/// le tromperait sur la rentabilité du propriétaire.
///
/// `expensesTotal` est lu sans être affiché aujourd'hui : le serveur le rend,
/// et le perdre au passage obligerait à retoucher le modèle le jour où l'écran
/// des dépenses du gérant s'en servira. Il ne doit jamais être soustrait de
/// `grossRevenue` — ce serait reconstituer le net que la conception écarte.
class GerantOverviewModel {
  const GerantOverviewModel({
    required this.bookingsCount,
    required this.grossRevenue,
    required this.expensesTotal,
    required this.occupancyRate,
    this.revenuePoints = const [],
  });

  /// Réservations comptées sur la fenêtre, sur ses seuls logements.
  final int bookingsCount;

  /// Encaissements bruts de la fenêtre, sans aucune charge déduite.
  final double grossRevenue;

  /// Charges portées par ses logements. Jamais retranchée du brut.
  final double expensesTotal;

  /// Part des jours-logement occupés, de 0 à 1.
  final double occupancyRate;

  final List<RevenuePointModel> revenuePoints;

  /// Relevé d'un gérant sans affectation, ou fraîchement nommé.
  static const empty = GerantOverviewModel(
    bookingsCount: 0,
    grossRevenue: 0,
    expensesTotal: 0,
    occupancyRate: 0,
  );

  factory GerantOverviewModel.fromJson(Map<String, dynamic> json) {
    return GerantOverviewModel(
      // Replis à zéro : un gérant fraîchement affecté n'a encore aucune
      // réservation, et le serveur peut omettre les agrégats correspondants.
      bookingsCount: (json['bookings_count'] as num?)?.toInt() ?? 0,
      grossRevenue: (json['gross_revenue'] as num?)?.toDouble() ?? 0,
      expensesTotal: (json['expenses_total'] as num?)?.toDouble() ?? 0,
      occupancyRate: (json['occupancy_rate'] as num?)?.toDouble() ?? 0,
      revenuePoints:
          (json['revenue_points'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(RevenuePointModel.fromJson)
              .toList() ??
          const [],
    );
  }

  /// Rend exactement les cinq champs du relevé serveur.
  ///
  /// Un test verrouille cette liste : y ajouter une clé nommant un net ferait
  /// tomber la suite avant que le chiffre n'atteigne l'écran du gérant.
  Map<String, dynamic> toJson() => {
    'bookings_count': bookingsCount,
    'gross_revenue': grossRevenue,
    'expenses_total': expensesTotal,
    'occupancy_rate': occupancyRate,
    'revenue_points': revenuePoints
        .map((point) => {'month': point.month, 'value': point.value})
        .toList(),
  };
}
