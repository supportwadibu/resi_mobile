import '../data/models/booking_stats_model.dart';
import '../data/models/reservation_model.dart';

sealed class ReservationState {
  const ReservationState();
}

final class ReservationInitial extends ReservationState {
  const ReservationInitial();
}

final class ReservationLoading extends ReservationState {
  const ReservationLoading();
}

final class ReservationLoaded extends ReservationState {
  const ReservationLoaded(this.items, {this.stats});
  final List<ReservationModel> items;

  /// Chiffres du tableau de bord, `null` tant qu'ils n'ont pas été obtenus.
  ///
  /// Portés par le même état que la liste : les compteurs dérivent des mêmes
  /// réservations, et les servir depuis un état séparé exposerait à afficher
  /// « 12 en cours » au-dessus d'une liste qui en montre trois.
  ///
  /// Reste `null` quand seul cet appel échoue : mieux vaut la liste sans ses
  /// chiffres qu'un écran vide.
  final BookingStatsModel? stats;
}

final class ReservationError extends ReservationState {
  const ReservationError(this.message);
  final String message;
}
