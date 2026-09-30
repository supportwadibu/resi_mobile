/// Règles du prix convenu d'une réservation comptoir.
///
/// Le serveur lit le prix saisi comme le **montant du séjour** : il devient
/// `total_amount`, et l'écart avec le tarif est enregistré comme remise. Saisir
/// à cet endroit l'argent reçu ce jour-là — un premier versement — produit un
/// séjour de onze jours à 15 000 F et 205 000 F de « remise ». Ces règles
/// servent à le montrer avant l'envoi, à la création comme à la modification.
abstract final class AgreedPrice {
  /// En dessous de cette part du tarif, le prix saisi ressemble plus à un
  /// versement qu'à une négociation. Seuil d'alerte, jamais de blocage : un
  /// geste commercial fort reste possible.
  static const double suspiciousRatio = 0.5;

  /// Remise consentie : l'écart entre tarif et prix convenu, jamais négative
  /// — même règle que le serveur.
  static double discount({required double expected, required double? agreed}) {
    if (agreed == null) return 0;
    return (expected - agreed).clamp(0, double.infinity).toDouble();
  }

  /// Le prix convenu est-il assez bas pour être un versement saisi au mauvais
  /// endroit ?
  static bool looksLikePayment({
    required double expected,
    required double? agreed,
  }) {
    if (agreed == null || expected <= 0) return false;
    return agreed < expected * suspiciousRatio;
  }
}
