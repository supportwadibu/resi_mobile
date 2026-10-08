import '../data/models/reservation_model.dart';

/// États de l'enregistrement de l'arrivée d'un client.
sealed class StayCheckInState {
  const StayCheckInState();
}

final class StayCheckInIdle extends StayCheckInState {
  const StayCheckInIdle();
}

final class StayCheckInSubmitting extends StayCheckInState {
  const StayCheckInSubmitting();
}

final class StayCheckInSuccess extends StayCheckInState {
  const StayCheckInSuccess(this.reservation, {this.queued = false});

  /// Réservation passée « en cours », `null` quand l'arrivée est en file.
  final ReservationModel? reservation;

  /// Arrivée saisie hors ligne, envoyée au retour du réseau.
  final bool queued;
}

/// Échec — réseau, arrivée hors du séjour, réservation déjà ouverte, close ou
/// annulée. Le message du serveur dit quoi faire ; rien ne se corrige depuis
/// l'écran.
final class StayCheckInFailure extends StayCheckInState {
  const StayCheckInFailure(this.message);

  final String message;
}
