/// Accès ouvert par l'abonnement du propriétaire, tel que l'API le décide.
///
/// Trois paliers, du plus réduit au plus complet, et un état bloquant :
/// - [free] — RESI Basic, gratuit : réservations, tableau de bord, revenus et
///   taux d'occupation ;
/// - [pro] — RESI Pro, 3 000 F / mois : en plus, dépenses, finances, carnet
///   clients ;
/// - [proPlus] — RESI Pro+, 5 000 F / mois : en plus, gérants, factures,
///   rapports PDF.
///
/// Un compte [inactive] est rejeté ou suspendu : un abonnement échu, lui,
/// retombe sur [free].
enum PlanAccess {
  proPlus('pro_plus', 2),
  pro('pro', 1),
  free('free', 0),
  inactive('inactive', -1);

  const PlanAccess(this.code, this._rank);

  final String code;
  final int _rank;

  /// Lit `plan_access` de `GET /proprio/subscription`.
  ///
  /// `null` y signifie « compte inactif ». `basic` et `full` sont les paliers
  /// d'un serveur antérieur aux offres actuelles : `basic` (3 000 F) est
  /// devenu Pro, `full` (5 000 F) Pro+. Un code inconnu vaut inactif : ouvrir
  /// par défaut laisserait l'écran promettre des fonctions que l'API
  /// refuserait aussitôt.
  static PlanAccess fromApi(String? code) => switch (code) {
    'pro_plus' || 'full' => PlanAccess.proPlus,
    'pro' || 'basic' => PlanAccess.pro,
    'free' => PlanAccess.free,
    _ => PlanAccess.inactive,
  };

  /// Relit la valeur mise en cache sur l'appareil. `null` si rien n'est connu.
  ///
  /// Le cache d'une version antérieure porte `basic` ou `full` : relus comme
  /// au serveur.
  static PlanAccess? fromCache(String? code) {
    if (code == null) return null;
    final access = fromApi(code);
    return access == PlanAccess.inactive && code != 'inactive' ? null : access;
  }

  /// Ce palier ouvre-t-il ce qu'exige [required] ?
  bool allows(PlanAccess required) => _rank >= required._rank;

  bool get isActive => this != PlanAccess.inactive;
}
