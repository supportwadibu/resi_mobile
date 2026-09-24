import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/repositories/reservation_repository.dart';
import 'early_check_out_state.dart';

/// Pilote le départ anticipé : chiffrage à l'heure de sortie choisie, puis
/// clôture au montant retenu.
///
/// Réseau requis, comme la clôture simple : rejouée plus tard, une clôture
/// daterait la sortie de l'instant du rejeu, et le chiffrage n'existe que
/// côté serveur.
class EarlyCheckOutCubit extends Cubit<EarlyCheckOutState> {
  EarlyCheckOutCubit(this._repository) : super(const EarlyCheckOutInitial());

  final ReservationRepository _repository;

  Future<void> quote(String bookingId, DateTime at) async {
    emit(const EarlyCheckOutLoading());

    try {
      final quote = await _repository.previewEarlyCheckOut(bookingId, at: at);
      if (!isClosed) emit(EarlyCheckOutLoaded(quote));
    } on AppFailure catch (f) {
      if (!isClosed) emit(EarlyCheckOutError(f.userMessage));
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

    emit(EarlyCheckOutLoaded(current, isSubmitting: true));

    try {
      final reservation = await _repository.checkOutEarly(
        bookingId,
        actualCheckOutAt: current.actualCheckOutAt,
        finalAmount: finalAmount.round(),
      );
      if (!isClosed) emit(EarlyCheckOutSuccess(reservation));
    } on AppFailure catch (f) {
      if (!isClosed) emit(EarlyCheckOutError(f.userMessage, quote: current));
    }
  }
}
