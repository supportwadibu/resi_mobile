import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../gerant/data/repositories/gerant_repository.dart';
import '../data/repositories/finance_repository.dart';
import 'dashboard_state.dart';

/// Chiffres de l'onglet Statistiques : occupation, entrées, sorties.
///
/// L'onglet est monté pour les deux rôles, mais le relevé du propriétaire est
/// fermé au gérant : `/gerant/finance/overview` rend un `ManagerOverviewDto`
/// sans clé `summary`, que `FinanceOverviewModel.fromJson` lirait entièrement à
/// zéro sans rien signaler. Le rôle est donc lu avant tout appel, et chaque
/// branche a sa source, son modèle et son état.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(
    this._financeRepository,
    this._gerantRepository,
    this._roleOf, {
    bool Function()? canReadFinance,
  }) : _canReadFinance = canReadFinance ?? (() => true),
       super(const DashboardInitial());

  /// Le palier ouvre-t-il le relevé financier (RESI Pro) ? Sous RESI Basic,
  /// l'onglet suit revenus et occupation par `finance/performance` : le relevé
  /// complet répondrait 403. Lu à chaque chargement, le palier changeant après
  /// un paiement.
  final bool Function() _canReadFinance;

  final FinanceRepository _financeRepository;
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

  /// Relevé du propriétaire sur la période.
  ///
  /// Une seule source : les compteurs d'unités louées et libres viennent du
  /// même relevé que le taux, sur la même fenêtre. Ils étaient lus sur
  /// `/proprio/properties/stats`, un instantané sans période dont le compteur
  /// `rented` reposait sur un statut que plus aucun flux n'écrit — la note
  /// affichait les mêmes chiffres quel que soit le mois choisi.
  Future<void> _loadOwner(DateTime start, DateTime end) async {
    try {
      final canReadFinance = _canReadFinance();
      final overview = canReadFinance
          ? await _financeRepository.getOverview(from: start, to: end)
          : await _financeRepository.getPerformance(from: start, to: end);

      if (isClosed) return;

      emit(
        DashboardLoaded(
          overview: overview,
          from: start,
          to: end,
          expensesVisible: canReadFinance,
        ),
      );
    } on AppFailure catch (f) {
      if (!isClosed) emit(DashboardError(f.userMessage));
    }
  }

  /// Relevé du gérant : un seul appel, sur son propre préfixe.
  ///
  /// Les compteurs d'unités louées et libres n'y figurent pas : son périmètre
  /// partiel ne les définit pas. Son taux d'occupation, lui, est servi par son
  /// propre relevé.
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
