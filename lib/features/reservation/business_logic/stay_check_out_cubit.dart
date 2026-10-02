import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../core/offline/offline_action_queue.dart';
import '../../../core/offline/pending_action.dart';
import '../data/repositories/reservation_repository.dart';
import 'stay_check_out_state.dart';

/// Pilote la clôture d'un séjour depuis sa fiche.
///
/// Hors réseau, la clôture part en file avec l'heure du geste : le serveur
/// accepte `actual_check_out_at` pour un départ complet, et un rejeu ne date
/// donc plus la sortie de l'instant de la synchronisation.
class StayCheckOutCubit extends Cubit<StayCheckOutState> {
  StayCheckOutCubit(this._repository, {OfflineActionQueue? queue})
    : _queue = queue,
      super(const StayCheckOutIdle());

  final ReservationRepository _repository;

  /// File hors ligne. Sans elle, une panne réseau s'affiche comme un échec.
  final OfflineActionQueue? _queue;

  Future<void> submit(String bookingId) async {
    emit(const StayCheckOutSubmitting());

    // Relevée avant l'envoi : c'est l'heure du départ, que la file transmet
    // si l'envoi part plus tard.
    final at = DateTime.now();
    final queue = _queue;

    // Une réservation encore en file n'existe pas au serveur : son départ la
    // suit dans la file au lieu d'essuyer un 404.
    if (queue != null && isLocalId(bookingId)) {
      return _enqueue(queue, bookingId, at);
    }

    try {
      final reservation = await _repository.checkOut(bookingId);
      if (!isClosed) emit(StayCheckOutSuccess(reservation));
    } on AppFailure catch (f) {
      if (isClosed) return;
      if (queue != null && OfflineActionQueue.isNetworkFailure(f)) {
        return _enqueue(queue, bookingId, at);
      }
      emit(StayCheckOutFailure(f.userMessage));
    }
  }

  Future<void> _enqueue(
    OfflineActionQueue queue,
    String bookingId,
    DateTime at,
  ) async {
    await queue.enqueue(
      PendingActionType.bookingCheckOut,
      targetRef: bookingId,
      payload: {'actual_check_out_at': at.toUtc().toIso8601String()},
    );
    if (!isClosed) emit(const StayCheckOutSuccess(null, queued: true));
  }
}
