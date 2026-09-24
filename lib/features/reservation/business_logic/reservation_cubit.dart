import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/models/booking_stats_model.dart';
import '../data/repositories/reservation_repository.dart';
import 'reservation_state.dart';

class ReservationCubit extends Cubit<ReservationState> {
  ReservationCubit(this._repository) : super(const ReservationInitial());
  final ReservationRepository _repository;

  Future<void> load() async {
    emit(const ReservationLoading());
    try {
      // Lancés ensemble : les deux appels sont indépendants, et les enchaîner
      // doublerait l'attente sur les réseaux lents auxquels l'application est
      // destinée.
      final itemsFuture = _repository.getReservationList();
      final statsFuture = _loadStats();

      final items = await itemsFuture;
      final stats = await statsFuture;

      if (!isClosed) emit(ReservationLoaded(items, stats: stats));
    } on AppFailure catch (f) {
      if (!isClosed) emit(ReservationError(f.userMessage));
    }
  }

  /// Chiffres du tableau de bord, `null` si leur chargement échoue.
  ///
  /// Accessoires à l'écran : mieux vaut la liste des réservations sans ses
  /// compteurs qu'un message d'erreur à la place de tout.
  Future<BookingStatsModel?> _loadStats() async {
    try {
      return await _repository.getStats();
    } on AppFailure {
      return null;
    }
  }
}
