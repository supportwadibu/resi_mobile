import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/models/finance/finance_period.dart';
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

  /// Période retenue, gardée ici pour la même raison que [_residenceId].
  FinancePeriod _period = const FinancePeriod.rolling();

  FinancePeriod get period => _period;

  DateTime? _from;
  DateTime? _to;

  /// Bornes du relevé affiché, dernier jour inclus.
  ///
  /// Exposées pour que l'écran annonce la période exacte des chiffres : les
  /// recalculer de son côté les ferait diverger d'un jour à l'autre, et le
  /// même `ca_brut` se lit très différemment selon la fenêtre — d'où la
  /// confusion avec l'onglet Statistiques, qui n'affiche qu'un mois.
  DateTime? get from => _from;
  DateTime? get to => _to;

  /// Charge la situation financière sur la période retenue.
  ///
  /// Par défaut, les douze derniers mois : le taux d'occupation a besoin d'une
  /// fenêtre pour avoir un dénominateur.
  Future<void> load() async {
    emit(const FinanceLoading());

    final bounds = _period.bounds(DateTime.now());
    _from = bounds.from;
    _to = bounds.to;

    try {
      final overview = await _repository.getOverview(
        from: bounds.from,
        to: bounds.to,
        residenceId: _residenceId,
      );
      if (!isClosed) emit(FinanceLoaded(overview));
    } on AppFailure catch (f) {
      if (!isClosed) emit(FinanceError(f.userMessage));
    }
  }

  Future<void> filterByResidence(String? residenceId) async {
    if (_residenceId == residenceId) return;

    _residenceId = residenceId;
    await load();
  }

  Future<void> filterByPeriod(FinancePeriod period) async {
    if (_period == period) return;

    _period = period;
    await load();
  }
}
