/// Écran à ouvrir quand le propriétaire touche une notification.
///
/// Lu sur le champ `type` des données posé par le serveur. Un type inconnu —
/// un serveur plus récent que l'application — n'ouvre rien : l'application
/// s'ouvre simplement, sans écran d'erreur.
enum PushDestination {
  /// Relance d'échéance : les forfaits, pour renouveler.
  subscription;

  static PushDestination? fromData(Map<String, dynamic> data) {
    return switch (data['type']) {
      'subscription_expiry' => PushDestination.subscription,
      _ => null,
    };
  }
}
