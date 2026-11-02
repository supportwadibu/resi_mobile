import '../data/models/reservation_model.dart';

/// États de la clôture d'un séjour.
sealed class StayCheckOutState {
  const StayCheckOutState();
}

final class StayCheckOutIdle extends StayCheckOutState {
  const StayCheckOutIdle();
}

final class StayCheckOutSubmitting extends StayCheckOutState {
  const StayCheckOutSubmitting();
}

final class StayCheckOutSuccess extends StayCheckOutState {
  const StayCheckOutSuccess(this.reservation, {this.queued = false});

  /// Réservation clôturée par le serveur, `null` quand le départ est en file.
  final ReservationModel? reservation;

  /// Départ saisi hors ligne, envoyé au retour du réseau.
  final bool queued;
}

/// Échec — réseau, séjour déjà clôturé ou annulé, séjour pas encore commencé.
///
/// Aucun cas ne mérite un état à part, contrairement au conflit de période de
/// la prolongation : aucun ne se corrige depuis l'écran, et le message du
/// serveur suffit à dire quoi faire.
final class StayCheckOutFailure extends StayCheckOutState {
  const StayCheckOutFailure(this.message);

  final String message;
}
