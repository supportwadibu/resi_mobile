import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/repositories/reservation_repository.dart';
import 'stay_check_out_state.dart';

/// Pilote la clôture d'un séjour depuis sa fiche.
///
/// Comme la prolongation, la clôture n'est pas mise en file hors réseau : elle
/// porte sur un séjour que le serveur connaît déjà, et une clôture rejouée plus
/// tard daterait la sortie réelle de l'instant du rejeu, pas de celui du geste.
class StayCheckOutCubit extends Cubit<StayCheckOutState> {
  StayCheckOutCubit(this._repository) : super(const StayCheckOutIdle());

  final ReservationRepository _repository;

  Future<void> submit(String bookingId) async {
    emit(const StayCheckOutSubmitting());

    try {
      final reservation = await _repository.checkOut(bookingId);
      if (!isClosed) emit(StayCheckOutSuccess(reservation));
    } on AppFailure catch (f) {
      if (!isClosed) emit(StayCheckOutFailure(f.userMessage));
    }
  }
}
