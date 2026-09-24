import '../../gerant/data/models/gerant_overview_model.dart';
import '../data/models/finance/finance_overview_model.dart';
import '../data/models/property_stats_model.dart';

sealed class DashboardState {
  const DashboardState();
}

final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

final class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.overview,
    required this.parc,
    required this.from,
    required this.to,
  });

  /// Revenus, charges et taux d'occupation sur [from]–[to].
  final FinanceOverviewModel overview;

  /// État du parc au moment de l'appel : les compteurs d'unités ignorent la
  /// période, seul le relevé financier en dépend.
  final PropertyStatsModel parc;

  final DateTime from;
  final DateTime to;
}

final class DashboardError extends DashboardState {
  const DashboardError(this.message);
  final String message;
}

/// Chiffres de l'onglet Statistiques d'un gérant.
///
/// Type distinct et non un `DashboardLoaded` dont les champs manquants
/// vaudraient zéro : celui-ci porte un `FinanceOverviewModel`, à qui un
/// `summary.beneficeNet` se demande en un accès de champ. Sur le périmètre
/// partiel d'un gérant, ce net n'est pas une marge partielle mais un chiffre
/// faux — il déduirait l'abonnement du propriétaire, les charges communes et
/// les dépenses d'autres logements. La séparation des types est ce qui
/// garantit qu'aucun oubli d'affichage ne puisse lui en montrer un.
///
/// Aucun compteur d'unités non plus : `/proprio/properties/stats` n'a pas
/// d'équivalent gérant, et le demander rendrait un 403. L'absence du champ
/// vaut mieux qu'un zéro, qui se lirait comme un parc vide.
final class DashboardManagerLoaded extends DashboardState {
  const DashboardManagerLoaded({
    required this.overview,
    required this.from,
    required this.to,
  });

  /// Réservations, encaissements bruts, charges et occupation de [from]–[to],
  /// sur ses seuls logements. Sans revenu net, par construction du modèle.
  final GerantOverviewModel overview;

  final DateTime from;
  final DateTime to;
}
