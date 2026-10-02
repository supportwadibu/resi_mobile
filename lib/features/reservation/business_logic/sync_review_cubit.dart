import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/offline/pending_action.dart';
import '../../../core/offline/pending_action_store.dart';
import '../../../core/sync/sync_service.dart';
import '../data/datasources/reservation_local_store.dart';

/// Saisie hors ligne refusée à l'envoi, telle que l'écran d'arbitrage la
/// présente.
class ReviewItem {
  const ReviewItem({
    required this.id,
    required this.isBooking,
    required this.kind,
    required this.state,
    required this.createdAt,
    this.detail,
    this.error,
    this.amount,
  });

  /// `client_request_id` d'une réservation, identifiant d'une action sinon.
  final String id;

  /// Réservation de `pending_bookings`, ou action de `pending_actions`.
  final bool isBooking;

  /// `booking` ou code de [PendingActionType] : clé du libellé affiché.
  final String kind;
  final PendingActionState state;
  final DateTime createdAt;

  /// Ce qui identifie la saisie pour le propriétaire : bien, client.
  final String? detail;

  /// Motif du refus, tel que le serveur l'a formulé.
  final String? error;

  /// Argent en jeu, rappelé avant tout abandon.
  final num? amount;
}

sealed class SyncReviewState {
  const SyncReviewState();
}

final class SyncReviewLoading extends SyncReviewState {
  const SyncReviewLoading();
}

final class SyncReviewLoaded extends SyncReviewState {
  const SyncReviewLoaded(this.items);

  final List<ReviewItem> items;
}

final class SyncReviewError extends SyncReviewState {
  const SyncReviewError(this.message);

  final String message;
}

/// Arbitrage des saisies hors ligne refusées : conflits de période et refus.
///
/// Aucune résolution automatique : le système ne sait pas lequel de deux
/// clients occupe le logement, et deviner reviendrait à effacer une saisie
/// payée. Le propriétaire renvoie — après avoir libéré la période, par
/// exemple — ou abandonne.
class SyncReviewCubit extends Cubit<SyncReviewState> {
  SyncReviewCubit(this._bookings, this._actions, this._sync)
    : super(const SyncReviewLoading());

  final ReservationLocalStore _bookings;
  final PendingActionStore _actions;
  final SyncService _sync;

  Future<void> load() async {
    try {
      final bookings = await _bookings.pendingBookingsAsJson();
      final actions = await _actions.all();

      final items = <ReviewItem>[
        for (final booking in bookings)
          if (_failed(booking['sync_status']) case final state?)
            ReviewItem(
              id: (booking['id'] as String).substring(localIdPrefix.length),
              isBooking: true,
              kind: 'booking',
              state: state,
              createdAt:
                  DateTime.tryParse(booking['created_at'] as String? ?? '') ??
                  DateTime.now(),
              detail: _bookingDetail(booking),
              error: booking['last_error'] as String?,
              amount: booking['received_amount'] as num?,
            ),
        for (final action in actions)
          if (action.state != PendingActionState.pending)
            ReviewItem(
              id: action.id,
              isBooking: false,
              kind: action.type.code,
              state: action.state,
              createdAt: action.createdAt,
              detail: _actionDetail(action),
              error: action.errorMessage,
              amount: _actionAmount(action),
            ),
      ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!isClosed) emit(SyncReviewLoaded(items));
    } catch (e) {
      if (!isClosed) emit(SyncReviewError(e.toString()));
    }
  }

  /// Remet la saisie en file et tente aussitôt l'envoi.
  Future<void> retry(ReviewItem item) async {
    if (item.isBooking) {
      await _bookings.requeue(item.id);
    } else {
      await _actions.mark(item.id, state: PendingActionState.pending);
    }
    await _sync.refreshCounters();
    await load();
    await _sync.synchronize();
    await load();
  }

  Future<void> discard(ReviewItem item) async {
    if (item.isBooking) {
      await _bookings.discard(item.id);
    } else {
      await _actions.remove(item.id);
    }
    await _sync.refreshCounters();
    await load();
  }

  static PendingActionState? _failed(Object? status) => switch (status) {
    'conflict' => PendingActionState.conflict,
    'rejected' => PendingActionState.rejected,
    _ => null,
  };

  static String? _bookingDetail(Map<String, dynamic> booking) {
    final property = (booking['property'] as Map?)?['title'] as String?;
    final client = (booking['client'] as Map?)?['full_name'] as String?;
    final parts = [property, client].whereType<String>().where(
      (p) => p.isNotEmpty,
    );
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String? _actionDetail(PendingAction action) {
    final p = action.payload;
    return switch (action.type) {
      PendingActionType.clientCreate || PendingActionType.clientUpdate =>
        p['full_name'] as String? ?? p['phone'] as String?,
      PendingActionType.expenseCreate =>
        ((p['_display'] as Map?)?.values.firstOrNull as Map?)?['title']
                as String? ??
            ((p['_display'] as Map?)?.values.firstOrNull as Map?)?['name']
                as String?,
      _ => null,
    };
  }

  static num? _actionAmount(PendingAction action) {
    final p = action.payload;
    return switch (action.type) {
      PendingActionType.expenseCreate => p['amount'] as num?,
      PendingActionType.bookingCheckOutEarly => p['final_amount'] as num?,
      PendingActionType.bookingExtend ||
      PendingActionType.bookingUpdate => p['received_amount'] as num?,
      _ => null,
    };
  }
}
