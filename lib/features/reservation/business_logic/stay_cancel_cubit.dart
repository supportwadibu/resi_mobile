import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/models/deposit_action.dart';
import '../data/repositories/reservation_repository.dart';
import 'stay_cancel_state.dart';

/// Pilote l'annulation d'une réservation depuis sa fiche.
///
/// Sans file hors ligne, contrairement à l'arrivée et à la clôture : le sort de
/// l'acompte est vérifié par le serveur, et une annulation rejouée plus tard
/// pourrait tomber sur un séjour entre-temps clôturé — le propriétaire la
/// croirait faite.
class StayCancelCubit extends Cubit<StayCancelState> {
  StayCancelCubit(this._repository) : super(const StayCancelIdle());

  final ReservationRepository _repository;

  Future<void> submit(
    String bookingId, {
    String? reason,
    DepositAction? depositAction,
  }) async {
    emit(const StayCancelSubmitting());

    try {
      final reservation = await _repository.cancel(
        bookingId,
        reason: reason,
        depositAction: depositAction,
      );
      if (!isClosed) emit(StayCancelSuccess(reservation));
    } on AppFailure catch (f) {
      if (!isClosed) emit(StayCancelFailure(f.userMessage));
    }
  }
}
