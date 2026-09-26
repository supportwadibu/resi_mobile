/// Accès ouvert par l'abonnement du propriétaire, tel que l'API le décide.
///
/// Deux paliers et un état bloquant : le forfait 3 000 F ([basic]) couvre
/// l'enregistrement — résidences, logements, réservations, clients saisis
/// pendant la réservation — ; le forfait 5 000 F ([full]) ouvre tout le reste.
/// Un compte [inactive] n'a aucun abonnement en cours et doit souscrire.
enum PlanAccess {
  full('full'),
  basic('basic'),
  inactive('inactive');

  const PlanAccess(this.code);

  final String code;

  /// Lit `plan_access` de `GET /proprio/subscription`.
  ///
  /// `null` y signifie « compte inactif ». Un code inconnu vaut aussi
  /// inactif : ouvrir par défaut laisserait l'écran promettre des fonctions
  /// que l'API refuserait aussitôt.
  static PlanAccess fromApi(String? code) => switch (code) {
    'full' => PlanAccess.full,
    'basic' => PlanAccess.basic,
    _ => PlanAccess.inactive,
  };

  /// Relit la valeur mise en cache sur l'appareil. `null` si rien n'est connu.
  static PlanAccess? fromCache(String? code) {
    for (final access in PlanAccess.values) {
      if (access.code == code) return access;
    }
    return null;
  }

  bool get isFull => this == PlanAccess.full;
  bool get isActive => this != PlanAccess.inactive;
}
