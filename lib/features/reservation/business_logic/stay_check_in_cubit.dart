import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../core/offline/offline_action_queue.dart';
import '../../../core/offline/pending_action.dart';
import '../data/repositories/reservation_repository.dart';
import 'stay_check_in_state.dart';

/// Pilote l'enregistrement de l'arrivée d'un client depuis la fiche.
///
/// Même contrat hors ligne que la clôture : l'arrivée part en file avec
/// l'heure du geste, que le serveur accepte (`actual_check_in_at`) — un rejeu
/// ne la date pas de l'instant de la synchronisation.
class StayCheckInCubit extends Cubit<StayCheckInState> {
  StayCheckInCubit(this._repository, {OfflineActionQueue? queue})
    : _queue = queue,
      super(const StayCheckInIdle());

  final ReservationRepository _repository;

  /// File hors ligne. Sans elle, une panne réseau s'affiche comme un échec.
  final OfflineActionQueue? _queue;

  Future<void> submit(String bookingId) async {
    emit(const StayCheckInSubmitting());

    // Relevée avant l'envoi : c'est l'heure de l'arrivée, que la file
    // transmet si l'envoi part plus tard.
    final at = DateTime.now();
    final queue = _queue;

    // Une réservation encore en file n'existe pas au serveur : son arrivée la
    // suit dans la file au lieu d'essuyer un 404.
    if (queue != null && isLocalId(bookingId)) {
      return _enqueue(queue, bookingId, at);
    }

    try {
      final reservation = await _repository.checkIn(bookingId);
      if (!isClosed) emit(StayCheckInSuccess(reservation));
    } on AppFailure catch (f) {
      if (isClosed) return;
      if (queue != null && OfflineActionQueue.isNetworkFailure(f)) {
        return _enqueue(queue, bookingId, at);
      }
      emit(StayCheckInFailure(f.userMessage));
    }
  }

  Future<void> _enqueue(
    OfflineActionQueue queue,
    String bookingId,
    DateTime at,
  ) async {
    await queue.enqueue(
      PendingActionType.bookingCheckIn,
      targetRef: bookingId,
      payload: {'actual_check_in_at': at.toUtc().toIso8601String()},
    );
    if (!isClosed) emit(const StayCheckInSuccess(null, queued: true));
  }
}
