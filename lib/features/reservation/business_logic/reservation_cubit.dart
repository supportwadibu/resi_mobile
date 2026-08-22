import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/reservation_repository.dart';
import 'reservation_state.dart';

class ReservationCubit extends Cubit<ReservationState> {
  ReservationCubit(this._repository) : super(const ReservationInitial());
  final ReservationRepository _repository;

  Future<void> load() async {
    emit(const ReservationLoading());
    try {
      final items = await _repository.getReservationList();
      if (!isClosed) emit(ReservationLoaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit(ReservationError(f.userMessage));
    }
  }
}
