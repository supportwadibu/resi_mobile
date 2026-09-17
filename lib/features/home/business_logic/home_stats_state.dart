sealed class HomeStatsState {
  const HomeStatsState();
}

final class HomeStatsInitial extends HomeStatsState {
  const HomeStatsInitial();
}

final class HomeStatsLoading extends HomeStatsState {
  const HomeStatsLoading();
}

/// Chiffres de la rangée d'accueil.
///
/// Chaque valeur est optionnelle : les trois relevés viennent de sources
/// distinctes, et l'échec de l'un ne doit pas vider les autres. Une tuile sans
/// valeur affiche un tiret plutôt qu'un zéro, qui se lirait comme un fait.
final class HomeStatsLoaded extends HomeStatsState {
  const HomeStatsLoaded({
    this.propertiesCount,
    this.activeBookings,
    this.netIncome,
  });

  /// Toutes les unités du parc, brouillons compris. Sans période : un parc ne
  /// se compte pas par mois.
  final int? propertiesCount;

  /// Séjours du mois à venir ou en cours.
  final int? activeBookings;

  /// Bénéfice net du mois — revenus moins charges. Négatif un mois de travaux,
  /// ce que l'affichage doit montrer plutôt que masquer à zéro.
  final double? netIncome;
}

final class HomeStatsError extends HomeStatsState {
  const HomeStatsError(this.message);
  final String message;
}

/// Chiffres de la rangée d'accueil d'un gérant.
///
/// Type distinct et non un champ de plus sur `HomeStatsLoaded` : celui-ci porte
/// `netIncome`, que `StatsRowWidget` affiche. Sur le périmètre partiel d'un
/// gérant, un net n'est pas une marge partielle mais un chiffre faux — il
/// déduirait l'abonnement du propriétaire, les charges communes et les dépenses
/// d'autres logements. La séparation des types est ce qui garantit qu'aucun
/// oubli d'affichage ne puisse lui en montrer un.
final class HomeStatsManagerLoaded extends HomeStatsState {
  const HomeStatsManagerLoaded({
    this.bookingsCount,
    this.grossRevenue,
    this.occupancyRate,
  });

  /// Réservations du mois sur ses seuls logements.
  final int? bookingsCount;

  /// Encaissements bruts du mois, aucune charge déduite.
  final double? grossRevenue;

  /// Part des jours-logement occupés, de 0 à 1.
  final double? occupancyRate;
}
