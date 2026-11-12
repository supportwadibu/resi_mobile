import '../data/models/arrival_model.dart';
import '../data/models/reservation_model.dart';

/// États de l'arrivée au comptoir : scan, fiche, encaissement, clés.
sealed class ArrivalState {
  const ArrivalState();
}

/// En attente d'un QR ou d'un PIN.
final class ArrivalScanning extends ArrivalState {
  const ArrivalScanning({this.message});

  /// Raison du dernier refus — code inconnu, trop d'essais —, à afficher
  /// sous le viseur.
  final String? message;
}

final class ArrivalLookingUp extends ArrivalState {
  const ArrivalLookingUp();
}

/// Réservation trouvée : ce qui est payé, ce qui reste, ce qui bloque.
final class ArrivalReady extends ArrivalState {
  const ArrivalReady(this.arrival, {this.busy = false, this.message});

  final ArrivalModel arrival;

  /// Encaissement ou validation en cours : boutons désactivés.
  final bool busy;

  /// Refus du dernier geste, affiché sur la fiche.
  final String? message;

  ArrivalReady copyWith({ArrivalModel? arrival, bool? busy, String? message}) =>
      ArrivalReady(
        arrival ?? this.arrival,
        busy: busy ?? this.busy,
        message: message,
      );
}

/// Arrivée enregistrée : les clés peuvent être remises.
final class ArrivalCompleted extends ArrivalState {
  const ArrivalCompleted(this.reservation);

  final ReservationModel reservation;
}
