import '../data/models/reservation_model.dart';

sealed class ReservationState { const ReservationState(); }

final class ReservationInitial extends ReservationState { const ReservationInitial(); }
final class ReservationLoading extends ReservationState { const ReservationLoading(); }
final class ReservationLoaded  extends ReservationState {
  const ReservationLoaded(this.items);
  final List<ReservationModel> items;
}
final class ReservationError extends ReservationState {
  const ReservationError(this.message);
  final String message;
}
