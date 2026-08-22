import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/repositories/finance_repository.dart';
import 'finance_state.dart';

class FinanceCubit extends Cubit<FinanceState> {
  FinanceCubit(this._repository) : super(const FinanceInitial());
  final FinanceRepository _repository;

  /// Charge la situation financière.
  ///
  /// Sans bornes, l'exercice porte sur les douze derniers mois : le taux
  /// d'occupation a besoin d'une fenêtre pour avoir un dénominateur.
  Future<void> load({DateTime? from, DateTime? to}) async {
    emit(const FinanceLoading());

    final now = DateTime.now();
    final start = from ?? DateTime(now.year - 1, now.month, now.day);

    try {
      final overview = await _repository.getOverview(from: start, to: to ?? now);
      if (!isClosed) emit(FinanceLoaded(overview));
    } on AppFailure catch (f) {
      if (!isClosed) emit(FinanceError(f.userMessage));
    }
  }
}
