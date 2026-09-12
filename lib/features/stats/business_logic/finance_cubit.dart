import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/repositories/finance_repository.dart';
import 'finance_state.dart';

class FinanceCubit extends Cubit<FinanceState> {
  FinanceCubit(this._repository) : super(const FinanceInitial());
  final FinanceRepository _repository;

  /// Résidence sur laquelle le relevé est restreint, `null` pour tout le parc.
  ///
  /// Mémorisée dans le cubit et non dans l'écran : celui-ci recharge à chaque
  /// retour de navigation, et un filtre porté par le widget serait perdu au
  /// premier aller-retour vers la saisie d'une dépense.
  String? _residenceId;

  String? get residenceId => _residenceId;

  /// Charge la situation financière.
  ///
  /// Sans bornes, l'exercice porte sur les douze derniers mois : le taux
  /// d'occupation a besoin d'une fenêtre pour avoir un dénominateur.
  Future<void> load({DateTime? from, DateTime? to}) async {
    emit(const FinanceLoading());

    final now = DateTime.now();
    final start = from ?? DateTime(now.year - 1, now.month, now.day);

    try {
      final overview = await _repository.getOverview(
        from: start,
        to: to ?? now,
        residenceId: _residenceId,
      );
      if (!isClosed) emit(FinanceLoaded(overview));
    } on AppFailure catch (f) {
      if (!isClosed) emit(FinanceError(f.userMessage));
    }
  }

  /// Restreint le relevé à une résidence, ou lève la restriction avec `null`.
  ///
  /// Le rechargement est immédiat : le filtre n'a pas d'existence propre à
  /// l'écran, seuls les chiffres qu'il produit en ont une.
  Future<void> filterByResidence(String? residenceId) async {
    if (_residenceId == residenceId) return;

    _residenceId = residenceId;
    await load();
  }
}
