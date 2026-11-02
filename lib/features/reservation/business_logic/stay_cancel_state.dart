import '../data/models/reservation_model.dart';

/// États de l'annulation d'une réservation.
sealed class StayCancelState {
  const StayCancelState();
}

final class StayCancelIdle extends StayCancelState {
  const StayCancelIdle();
}

final class StayCancelSubmitting extends StayCancelState {
  const StayCancelSubmitting();
}

final class StayCancelSuccess extends StayCancelState {
  const StayCancelSuccess(this.reservation);

  final ReservationModel reservation;
}

/// Échec — réseau, séjour déjà clos ou annulé. Affiché dans la feuille, qui
/// reste ouverte pour réessayer.
final class StayCancelFailure extends StayCancelState {
  const StayCancelFailure(this.message);

  final String message;
}
