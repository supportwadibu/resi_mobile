import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../core/offline/offline_action_queue.dart';
import '../../../core/offline/pending_action.dart';
import '../data/models/early_check_out_quote.dart';
import '../data/models/reservation_model.dart';
import '../data/repositories/reservation_repository.dart';
import 'early_check_out_state.dart';

/// Pilote le départ anticipé : chiffrage à l'heure de sortie choisie, puis
/// clôture au montant retenu.
///
/// Hors réseau, le chiffrage se fait sur l'appareil par la règle du serveur
/// et la clôture part en file avec son heure et son montant : le rejeu ne
/// date donc pas la sortie de l'instant de la synchronisation, et le serveur
/// n'applique pas un autre prorata que celui annoncé au client.
class EarlyCheckOutCubit extends Cubit<EarlyCheckOutState> {
  EarlyCheckOutCubit(this._repository, {OfflineActionQueue? queue})
    : _queue = queue,
      super(const EarlyCheckOutInitial());

  final ReservationRepository _repository;

  /// File hors ligne. Sans elle, une panne réseau s'affiche comme un échec.
  final OfflineActionQueue? _queue;

  /// Chiffre un départ à [at].
  ///
  /// [reservation] permet le chiffrage sur l'appareil quand le serveur est
  /// injoignable — ou ignore encore la réservation, saisie hors ligne.
  Future<void> quote(
    String bookingId,
    DateTime at, {
    ReservationModel? reservation,
  }) async {
    emit(const EarlyCheckOutLoading());

    if (reservation != null && _queue != null && isLocalId(bookingId)) {
      return _estimate(reservation, at);
    }

    try {
      final quote = await _repository.previewEarlyCheckOut(bookingId, at: at);
      if (!isClosed) emit(EarlyCheckOutLoaded(quote));
    } on AppFailure catch (f) {
      if (isClosed) return;
      if (reservation != null &&
          _queue != null &&
          OfflineActionQueue.isNetworkFailure(f)) {
        return _estimate(reservation, at);
      }
      emit(EarlyCheckOutError(f.userMessage));
    }
  }

  /// Clôture au montant [finalAmount], sur le chiffrage affiché.
  ///
  /// L'heure envoyée est celle du chiffrage et non celle du champ : c'est sur
  /// elle que le propriétaire a lu le montant qu'il valide.
  Future<void> submit(String bookingId, double finalAmount) async {
    final current = switch (state) {
      EarlyCheckOutLoaded(:final quote) => quote,
      EarlyCheckOutError(:final quote?) => quote,
      _ => null,
    };
    if (current == null) return;

    final estimated = state is EarlyCheckOutLoaded &&
        (state as EarlyCheckOutLoaded).isEstimate;
    emit(
      EarlyCheckOutLoaded(current, isSubmitting: true, isEstimate: estimated),
    );

    final queue = _queue;
    if (queue != null && isLocalId(bookingId)) {
      return _enqueue(queue, bookingId, current, finalAmount);
    }

    try {
      final reservation = await _repository.checkOutEarly(
        bookingId,
        actualCheckOutAt: current.actualCheckOutAt,
        finalAmount: finalAmount.round(),
      );
      if (!isClosed) emit(EarlyCheckOutSuccess(reservation));
    } on AppFailure catch (f) {
      if (isClosed) return;
      if (queue != null && OfflineActionQueue.isNetworkFailure(f)) {
        return _enqueue(queue, bookingId, current, finalAmount);
      }
      emit(EarlyCheckOutError(f.userMessage, quote: current));
    }
  }

  void _estimate(ReservationModel reservation, DateTime at) {
    try {
      final quote = EarlyCheckOutQuote.estimate(reservation, at);
      if (!isClosed) emit(EarlyCheckOutLoaded(quote, isEstimate: true));
    } on EarlyCheckOutRefusal catch (refusal) {
      if (!isClosed) {
        emit(EarlyCheckOutError('stay_checkout.refusal.${refusal.code}'.tr()));
      }
    }
  }

  Future<void> _enqueue(
    OfflineActionQueue queue,
    String bookingId,
    EarlyCheckOutQuote quote,
    double finalAmount,
  ) async {
    await queue.enqueue(
      PendingActionType.bookingCheckOutEarly,
      targetRef: bookingId,
      // Le montant part explicitement : sans lui, le serveur appliquerait son
      // propre prorata, que le propriétaire n'a pas vu au comptoir.
      payload: {
        'actual_check_out_at': quote.actualCheckOutAt.toUtc().toIso8601String(),
        'final_amount': finalAmount.round(),
      },
    );
    if (!isClosed) emit(const EarlyCheckOutSuccess(null, queued: true));
  }
}
