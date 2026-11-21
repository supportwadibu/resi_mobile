/// Écran à ouvrir quand le propriétaire touche une notification.
///
/// Lu sur le champ `type` des données posé par le serveur. Un type inconnu —
/// un serveur plus récent que l'application — n'ouvre rien : l'application
/// s'ouvre simplement, sans écran d'erreur.
enum PushDestination {
  /// Relance d'échéance : les forfaits, pour renouveler.
  subscription,

  /// Nouvelle réservation sur un de ses biens : la liste des réservations.
  reservations,

  /// Retrait versé sur son compte Wave : le portefeuille.
  wallet;

  static PushDestination? fromData(Map<String, dynamic> data) {
    return switch (data['type']) {
      'subscription_expiry' => PushDestination.subscription,
      'booking_created' => PushDestination.reservations,
      'withdrawal_paid' => PushDestination.wallet,
      _ => null,
    };
  }
}
