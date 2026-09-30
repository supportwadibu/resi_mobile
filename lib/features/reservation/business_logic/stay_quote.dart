import '../../property/data/models/property_model.dart';
import '../data/models/reservation_model.dart';

/// Chiffrage d'un séjour comptoir, tel que le serveur le calculera.
///
/// Partagé par la création et la modification : deux copies de la règle
/// annonceraient deux montants attendus différents pour le même séjour.
/// Reprend `computeOwnerBookingAmounts` du serveur — ratios par type de
/// séjour, jours entamés, palier de durée sur le séjour complet.
class StayQuote {
  const StayQuote({
    required this.dailyPrice,
    required this.priceTiers,
    required this.stayType,
    required this.checkInAt,
    required this.checkOutAt,
  });

  final double dailyPrice;
  final List<PriceTier> priceTiers;
  final StayType stayType;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;

  /// Tarif d'une unité du type de séjour choisi.
  ///
  /// Reprend les ratios du serveur : la demi-journée vaut la moitié du tarif
  /// journalier, le passage 30 %.
  double get unitPrice => switch (stayType) {
    StayType.fullDay => dailyPrice,
    StayType.halfDay => (dailyPrice * 0.5).roundToDouble(),
    StayType.passage => (dailyPrice * 0.3).roundToDouble(),
  };

  /// Nombre de jours facturés, au minimum un.
  int get daysCount {
    if (stayType != StayType.fullDay) return 1;
    final start = checkInAt;
    final end = checkOutAt;
    if (start == null || end == null) return 1;

    final hours = end.difference(start).inMinutes / 60;
    return hours <= 0 ? 1 : (hours / 24).ceil().clamp(1, 3650);
  }

  /// Remise de durée applicable au séjour saisi, en pourcentage.
  ///
  /// Reprend `resolveDiscountPercent` du serveur : le palier retenu est le plus
  /// avantageux atteint, et non le dernier déclaré — la grille d'un bien
  /// enregistré avant sa normalisation peut être désordonnée.
  ///
  /// Les séjours infra-journaliers en sont exclus : ils valent un jour, quand
  /// le palier le plus court admis par le serveur en couvre deux.
  int get discountPercent {
    if (stayType != StayType.fullDay || priceTiers.isEmpty) return 0;

    var best = 0;
    for (final tier in priceTiers) {
      if (daysCount >= tier.minDays && tier.discountPercent > best) {
        best = tier.discountPercent;
      }
    }

    return best.clamp(0, 100);
  }

  /// Montant attendu selon la grille du bien, remise de durée comprise, avant
  /// négociation.
  ///
  /// L'arrondi au franc reproduit celui du serveur : sans lui, l'écran
  /// annoncerait au comptoir un montant que la facture ne confirmerait pas.
  double get expectedAmount =>
      (unitPrice * daysCount * (1 - discountPercent / 100)).roundToDouble();

  /// Montant avant remise de durée, pour montrer ce que le palier fait gagner.
  double get fullAmount => (unitPrice * daysCount).roundToDouble();
}
