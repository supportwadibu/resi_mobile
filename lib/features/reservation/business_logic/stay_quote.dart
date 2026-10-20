import '../../property/data/models/property_model.dart';
import '../data/models/reservation_model.dart';
import '../../../shared/models/late_checkout_policy.dart';

export '../../../shared/models/late_checkout_policy.dart';

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
    this.explicitDaysCount,
    this.lateCheckoutPolicy = const LateCheckoutPolicy(),
  });

  final double dailyPrice;
  final List<PriceTier> priceTiers;
  final StayType stayType;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final int? explicitDaysCount;

  /// Règle de départ tardif du bien ; celle du serveur par défaut.
  final LateCheckoutPolicy lateCheckoutPolicy;

  /// Tarif d'une unité du type de séjour choisi.
  ///
  /// Reprend les ratios du serveur : la demi-journée vaut la moitié du tarif
  /// journalier, le passage 30 %.
  double get unitPrice => switch (stayType) {
    StayType.fullDay => dailyPrice,
    StayType.halfDay => (dailyPrice * 0.5).roundToDouble(),
    StayType.passage => (dailyPrice * 0.3).roundToDouble(),
  };

  /// Jours facturés et départ tardif, selon la règle du bien.
  ///
  /// Si le propriétaire a choisi un nombre de jours explicite (Option 1), ce
  /// choix fait foi pour les jours : une sortie à 15h le lendemain d'une
  /// entrée à 12h reste 1 jour, plus une demi-journée de départ tardif.
  BilledStay get _billed {
    if (stayType != StayType.fullDay) {
      return const BilledStay(1, lateCheckout: false);
    }
    final explicit = explicitDaysCount != null && explicitDaysCount! >= 1
        ? explicitDaysCount
        : null;
    final start = checkInAt;
    final end = checkOutAt;
    if (start == null || end == null || !end.isAfter(start)) {
      return BilledStay(explicit ?? 1, lateCheckout: false);
    }
    return lateCheckoutPolicy.resolve(start, end, explicitDays: explicit);
  }

  /// Nombre de jours facturés, au minimum un.
  int get daysCount => _billed.days;

  /// Le dépassement des jours facturés se paie en demi-journée.
  bool get lateCheckout => _billed.lateCheckout;

  /// Supplément de départ tardif au tarif de la grille ; 0 sans dépassement.
  ///
  /// Au tarif plein, comme au serveur : la remise de durée ne porte que sur
  /// les jours.
  double get lateCheckoutFee =>
      lateCheckout ? LateCheckoutPolicy.feeFor(unitPrice) : 0;

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
      (unitPrice * daysCount * (1 - discountPercent / 100)).roundToDouble() +
      lateCheckoutFee;

  /// Montant des jours avant remise de durée, pour montrer ce que le palier
  /// fait gagner. Hors départ tardif, que la remise ne touche pas.
  double get fullAmount => (unitPrice * daysCount).roundToDouble();

  /// Remise de durée, en montant.
  double get durationDiscount => fullAmount + lateCheckoutFee - expectedAmount;

  /// Montant à un prix convenu par unité : les jours, et le départ tardif au
  /// même prix — comme `resolveAgreedAmount` au serveur.
  double agreedAmount(double unit) =>
      (unit * daysCount).roundToDouble() +
      (lateCheckout ? LateCheckoutPolicy.feeFor(unit) : 0);
}
