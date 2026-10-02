import '../data/models/reservation_model.dart';

/// États de la prolongation d'un séjour.
sealed class StayExtensionState {
  const StayExtensionState();
}

final class StayExtensionIdle extends StayExtensionState {
  const StayExtensionIdle();
}

final class StayExtensionSubmitting extends StayExtensionState {
  const StayExtensionSubmitting();
}

final class StayExtensionSuccess extends StayExtensionState {
  const StayExtensionSuccess(this.reservation, {this.queued = false});

  /// Réservation telle que le serveur l'a réécrite : c'est elle qui porte le
  /// montant réellement dû, pas l'estimation affichée avant l'envoi. `null`
  /// quand la prolongation est en file.
  final ReservationModel? reservation;

  /// Prolongation saisie hors ligne, envoyée au retour du réseau.
  final bool queued;
}

/// Échec ordinaire — réseau, montant refusé, séjour déjà clôturé.
final class StayExtensionFailure extends StayExtensionState {
  const StayExtensionFailure(this.message);

  final String message;
}

/// Le bien est déjà réservé sur la période demandée.
///
/// Distinct de [StayExtensionFailure] : ce n'est pas une panne à réessayer mais
/// un conflit à arbitrer, et le propriétaire doit pouvoir raccourcir sa demande
/// plutôt que de voir un message d'erreur générique.
final class StayExtensionConflict extends StayExtensionState {
  const StayExtensionConflict(this.message);

  final String message;
}
