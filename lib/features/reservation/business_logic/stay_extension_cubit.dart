import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../core/offline/offline_action_queue.dart';
import '../../../core/offline/pending_action.dart';
import '../data/repositories/reservation_repository.dart';
import 'stay_extension_state.dart';

/// Pilote la prolongation d'un séjour comptoir.
///
/// Séparé du cubit de liste : un échec de prolongation ne doit pas vider les
/// réservations affichées derrière.
class StayExtensionCubit extends Cubit<StayExtensionState> {
  StayExtensionCubit(this._repository, {OfflineActionQueue? queue})
    : _queue = queue,
      super(const StayExtensionIdle());

  final ReservationRepository _repository;

  /// File hors ligne. Sans elle, une panne réseau s'affiche comme un échec.
  final OfflineActionQueue? _queue;

  /// Repousse la sortie d'un séjour.
  ///
  /// [receivedAmount] est le montant renégocié avec le client ; à défaut, le
  /// serveur réajuste sur le nouveau montant attendu — laisser l'ancien
  /// montant ferait apparaître un impayé qui n'existe pas.
  ///
  /// Hors réseau, la prolongation part en file. Deux prolongations du même
  /// séjour s'y ordonnent par leur heure de saisie, et un chevauchement
  /// découvert à l'envoi devient un conflit à arbitrer par le propriétaire —
  /// jamais une saisie perdue.
  Future<void> submit({
    required String bookingId,
    required DateTime checkOutAt,
    num? receivedAmount,
  }) async {
    emit(const StayExtensionSubmitting());

    final queue = _queue;
    if (queue != null && isLocalId(bookingId)) {
      return _enqueue(queue, bookingId, checkOutAt, receivedAmount);
    }

    try {
      final reservation = await _repository.extend(
        bookingId,
        checkOutAt: checkOutAt,
        receivedAmount: receivedAmount,
      );

      if (!isClosed) emit(StayExtensionSuccess(reservation));
    } on AppFailure catch (f) {
      if (isClosed) return;

      if (queue != null && OfflineActionQueue.isNetworkFailure(f)) {
        return _enqueue(queue, bookingId, checkOutAt, receivedAmount);
      }

      // Le `statusCode` distingue la cause, jamais le texte du message : 409
      // est un refus métier à présenter tel quel, pas une panne à réessayer.
      //
      // Le serveur en renvoie trois — période déjà réservée, séjour clôturé,
      // réservation annulée — que `AppFailure` ne sépare pas, ne portant pas
      // le `code` métier. Sans conséquence ici : le message du serveur est
      // propagé tel quel, et les trois se présentent de la même façon. Les
      // distinguer supposerait d’exposer `code` sur `AppFailure`, ce qui
      // touche tous les appelants.
      emit(
        f.statusCode == 409
            ? StayExtensionConflict(f.userMessage)
            : StayExtensionFailure(f.userMessage),
      );
    }
  }

  Future<void> _enqueue(
    OfflineActionQueue queue,
    String bookingId,
    DateTime checkOutAt,
    num? receivedAmount,
  ) async {
    await queue.enqueue(
      PendingActionType.bookingExtend,
      targetRef: bookingId,
      payload: {
        'check_out_at': checkOutAt.toUtc().toIso8601String(),
        'received_amount': ?receivedAmount,
      },
    );
    if (!isClosed) emit(const StayExtensionSuccess(null, queued: true));
  }
}
