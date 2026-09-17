import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../gerant/data/models/gerant_overview_model.dart';
import '../../gerant/data/repositories/gerant_repository.dart';
import '../../reservation/data/repositories/reservation_repository.dart';
import '../../stats/data/repositories/finance_repository.dart';
import '../../stats/data/repositories/property_stats_repository.dart';
import 'home_stats_state.dart';

/// Chiffres de la rangée d'accueil.
///
/// Un seul cubit pour les deux rôles, et non un second pour le gérant : le
/// rechargement de la rangée est câblé par type dans `HomeScreen` — au retour
/// d'une saisie et au retour sur l'onglet. Le dupliquer laisserait, le jour où
/// l'un des deux branchements serait oublié, un gérant devant les chiffres
/// d'avant sa dernière réservation.
class HomeStatsCubit extends Cubit<HomeStatsState> {
  HomeStatsCubit(
    this._properties,
    this._bookings,
    this._finance,
    this._gerant,
    this._roleOf,
  ) : super(const HomeStatsInitial());

  final PropertyStatsRepository _properties;
  final ReservationRepository _bookings;
  final FinanceRepository _finance;
  final GerantRepository _gerant;

  /// Lecture du rôle courant, injectée pour rester testable hors widget —
  /// même forme que dans `OwnerRouteGuard`.
  final String Function() _roleOf;

  Future<void> load() async {
    emit(const HomeStatsLoading());

    if (_roleOf() == 'gerant') {
      await _loadManager();
      return;
    }

    await _loadOwner();
  }

  /// Rangée du propriétaire : parc, séjours du mois, bénéfice net.
  ///
  /// Trois sources, car les trois notions ne se recouvrent pas : le parc n'a
  /// pas de période, les séjours portent sur le mois en cours, le bénéfice net
  /// rapproche revenus et charges sur cette même fenêtre.
  Future<void> _loadOwner() async {
    // Lancés ensemble : les trois appels sont indépendants, et les enchaîner
    // triplerait l'attente sur les connexions lentes du terrain.
    //
    // Chacun est rattrapé séparément : une tuile manquante vaut mieux qu'une
    // rangée vide, et rien ici n'est indispensable à l'écran.
    final results = await Future.wait([
      _guard(() async => (await _properties.getStats()).total),
      _guard(() async {
        final stats = await _bookings.getStats();
        return stats.upcoming + stats.inProgress;
      }),
      _guard(() async {
        final overview = await _finance.getOverview(
          from: _startOfMonth(),
          to: DateTime.now(),
        );
        return overview.summary.beneficeNet;
      }),
    ]);

    if (isClosed) return;

    emit(
      HomeStatsLoaded(
        propertiesCount: results[0]?.toInt(),
        activeBookings: results[1]?.toInt(),
        netIncome: results[2]?.toDouble(),
      ),
    );
  }

  /// Rangée du gérant : réservations, encaissements, occupation du mois.
  ///
  /// Un seul appel là où le propriétaire en fait trois. `properties/stats` et
  /// `bookings/stats` n'ont aucun équivalent gérant : les appeler rendrait deux
  /// 403 et des tirets là où le relevé gérant porte déjà les trois chiffres.
  ///
  /// Aucun bénéfice net n'est demandé ni calculé — `GET /gerant/finance/overview`
  /// n'en rend aucun, et le reconstituer en retranchant `expenses_total` du brut
  /// donnerait un chiffre faux sur un périmètre partiel.
  Future<void> _loadManager() async {
    final overview = await _guardOverview(
      () => _gerant.getOverview(from: _startOfMonth(), to: DateTime.now()),
    );

    if (isClosed) return;

    emit(
      HomeStatsManagerLoaded(
        bookingsCount: overview?.bookingsCount,
        grossRevenue: overview?.grossRevenue,
        occupancyRate: overview?.occupancyRate,
      ),
    );
  }

  /// Premier jour du mois courant.
  ///
  /// Du 1er à aujourd'hui, comme l'onglet Statistiques : le même relevé lu sur
  /// deux fenêtres différentes donnerait deux chiffres du mois.
  static DateTime _startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// Exécute un relevé, ou rend `null` s'il échoue.
  Future<num?> _guard(Future<num> Function() run) async {
    try {
      return await run();
    } on AppFailure {
      return null;
    }
  }

  /// Même repli pour le relevé du gérant, qui rend un modèle et non un nombre.
  ///
  /// L'échec laisse les trois tuiles au tiret plutôt qu'à zéro, qui se lirait
  /// comme un fait — un gérant sans réservation et un relevé en panne ne sont
  /// pas la même information.
  Future<GerantOverviewModel?> _guardOverview(
    Future<GerantOverviewModel> Function() run,
  ) async {
    try {
      return await run();
    } on AppFailure {
      return null;
    }
  }
}
