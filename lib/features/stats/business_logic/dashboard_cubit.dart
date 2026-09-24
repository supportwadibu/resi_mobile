import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../gerant/data/repositories/gerant_repository.dart';
import '../data/models/finance/finance_overview_model.dart';
import '../data/models/property_stats_model.dart';
import '../data/repositories/finance_repository.dart';
import '../data/repositories/property_stats_repository.dart';
import 'dashboard_state.dart';

/// Chiffres de l'onglet Statistiques : occupation, entrées, sorties.
///
/// L'onglet est monté pour les deux rôles, mais les deux relevés du
/// propriétaire sont fermés au gérant : `/proprio/properties/stats` n'a aucun
/// équivalent gérant, et `/gerant/finance/overview` rend un `ManagerOverviewDto`
/// sans clé `summary`, que `FinanceOverviewModel.fromJson` lirait entièrement à
/// zéro sans rien signaler. Le rôle est donc lu avant tout appel, et chaque
/// branche a sa source, son modèle et son état.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(
    this._financeRepository,
    this._parcRepository,
    this._gerantRepository,
    this._roleOf,
  ) : super(const DashboardInitial());

  final FinanceRepository _financeRepository;
  final PropertyStatsRepository _parcRepository;
  final GerantRepository _gerantRepository;

  /// Lecture du rôle courant, injectée pour rester testable hors widget —
  /// même forme que dans `HomeStatsCubit` et `OwnerRouteGuard`.
  final String Function() _roleOf;

  DateTime? _from;
  DateTime? _to;

  DateTime? get from => _from;
  DateTime? get to => _to;

  /// Charge la période demandée, le mois courant par défaut.
  ///
  /// Le mois courant plutôt que l'année : l'en-tête de l'onglet annonce un
  /// mois, les chiffres affichés doivent porter sur la même fenêtre.
  Future<void> load({DateTime? from, DateTime? to}) async {
    final now = DateTime.now();
    final start = from ?? _from ?? DateTime(now.year, now.month);
    final end = to ?? _to ?? now;

    _from = start;
    _to = end;

    emit(const DashboardLoading());

    if (_roleOf() == 'gerant') {
      await _loadManager(start, end);
      return;
    }

    await _loadOwner(start, end);
  }

  /// Relevé du propriétaire : finances de la période et état du parc.
  ///
  /// Deux sources, car les deux notions ne se recouvrent pas : le relevé
  /// financier porte sur une période, l'état du parc décrit l'instant présent.
  Future<void> _loadOwner(DateTime start, DateTime end) async {
    try {
      // En parallèle : les deux relevés sont indépendants, et les enchaîner
      // doublerait l'attente sur les connexions lentes du terrain.
      //
      // L'échec de l'un fait échouer l'ensemble, à dessein : les deux nourrissent
      // la même carte d'occupation, dont le taux et les compteurs d'unités se
      // lisent l'un par l'autre. N'en montrer qu'une moitié induirait en erreur.
      final results = await Future.wait([
        _financeRepository.getOverview(from: start, to: end),
        _parcRepository.getStats(),
      ]);

      if (isClosed) return;

      emit(
        DashboardLoaded(
          overview: results[0] as FinanceOverviewModel,
          parc: results[1] as PropertyStatsModel,
          from: start,
          to: end,
        ),
      );
    } on AppFailure catch (f) {
      if (!isClosed) emit(DashboardError(f.userMessage));
    }
  }

  /// Relevé du gérant : un seul appel, sur son propre préfixe.
  ///
  /// L'état du parc n'est pas demandé — la route est propriétaire, et
  /// l'appeler rendrait un 403 `forbidden_role` qui ferait échouer tout
  /// l'onglet. Ce que le gérant y perd tient aux compteurs d'unités louées et
  /// disponibles, que son périmètre partiel ne définit pas ; son taux
  /// d'occupation, lui, est servi par son propre relevé.
  ///
  /// Aucun bénéfice net n'est demandé ni reconstitué en retranchant
  /// `expensesTotal` du brut : sur un périmètre partiel, le chiffre serait faux.
  Future<void> _loadManager(DateTime start, DateTime end) async {
    try {
      final overview = await _gerantRepository.getOverview(
        from: start,
        to: end,
      );

      if (isClosed) return;

      emit(DashboardManagerLoaded(overview: overview, from: start, to: end));
    } on AppFailure catch (f) {
      if (!isClosed) emit(DashboardError(f.userMessage));
    }
  }

  /// Rejoue le relevé sur une nouvelle période.
  Future<void> filterByPeriod(DateTime from, DateTime to) =>
      load(from: from, to: to);
}
