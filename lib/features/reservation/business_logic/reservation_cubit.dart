import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/models/booking_stats_model.dart';
import '../data/models/reservation_model.dart';
import '../data/repositories/reservation_repository.dart';
import 'reservation_state.dart';

/// Ce qu'une liste de réservations charge : un écran n'a pas les besoins d'un
/// autre, et les chiffres du tableau de bord coûtent un appel de plus.
class ReservationListOptions {
  const ReservationListOptions({
    this.propertyId,
    this.perPage = 20,
    this.withStats = false,
  });

  /// Aperçu de l'onglet : les cinq plus récentes et les chiffres du mois.
  /// Demander cinq lignes plutôt que d'en tronquer vingt épargne les lectures
  /// Firestore et le poids de la réponse.
  static const recent = ReservationListOptions(perPage: 5, withStats: true);

  /// Restreint la liste à un bien, pour sa fiche.
  final String? propertyId;

  final int perPage;

  /// Charge aussi les chiffres du tableau de bord, qui portent sur le parc
  /// entier.
  final bool withStats;
}

class ReservationCubit extends Cubit<ReservationState> {
  ReservationCubit(
    this._repository, {
    this.options = const ReservationListOptions(),
  }) : super(const ReservationInitial());

  final ReservationRepository _repository;
  final ReservationListOptions options;

  ReservationStatus? _status;
  String _query = '';
  int _page = 1;

  /// Incrémenté à chaque relecture depuis la première page : une page
  /// suivante demandée avant un changement de filtre ne doit pas s'ajouter à
  /// la nouvelle liste.
  int _generation = 0;

  /// Statut filtré, `null` pour toutes les réservations.
  ReservationStatus? get status => _status;

  Future<void> load() async {
    final generation = ++_generation;
    emit(const ReservationLoading());
    try {
      // Lancés ensemble : les deux appels sont indépendants, et les enchaîner
      // doublerait l'attente sur les réseaux lents auxquels l'application est
      // destinée.
      final pageFuture = _fetch(1);
      final statsFuture = options.withStats
          ? _loadStats()
          : Future<BookingStatsModel?>.value();

      final page = await pageFuture;
      final stats = await statsFuture;

      if (!isClosed && generation == _generation) {
        emit(_loaded(page, stats: stats));
      }
    } on AppFailure catch (f) {
      if (!isClosed && generation == _generation) {
        emit(ReservationError(f.userMessage));
      }
    }
  }

  /// Change le statut filtré et relit la liste depuis la première page.
  ///
  /// Filtré par le serveur et non sur les pages chargées : une réservation
  /// annulée plus ancienne n'apparaîtrait qu'une fois toutes les pages
  /// récentes parcourues.
  Future<void> setStatus(ReservationStatus? status) async {
    if (status == _status) return;
    _status = status;

    final generation = ++_generation;
    final current = state;
    final stats = current is ReservationLoaded ? current.stats : null;
    emit(ReservationLoading(stats: stats));
    try {
      final page = await _fetch(1);
      if (!isClosed && generation == _generation) {
        emit(_loaded(page, stats: stats));
      }
    } on AppFailure catch (f) {
      if (!isClosed && generation == _generation) {
        emit(ReservationError(f.userMessage));
      }
    }
  }

  /// Ajoute la page suivante à la liste. Sans effet pendant un chargement ou
  /// quand tout est déjà là : le défilement l'appelle à répétition.
  Future<void> loadMore() async {
    final current = state;
    if (current is! ReservationLoaded ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }

    final generation = _generation;
    emit(current.copyWith(isLoadingMore: true, clearLoadMoreError: true));
    try {
      final page = await _fetch(_page + 1);
      // Relu après l'attente : la recherche a pu changer entre-temps.
      final latest = state;
      if (isClosed ||
          generation != _generation ||
          latest is! ReservationLoaded) {
        return;
      }
      _page = page.page;

      // Une réservation créée entre deux pages décale le découpage du
      // serveur : la dernière ligne d'une page revient en tête de la
      // suivante. Dédoublonner évite de l'afficher deux fois.
      final known = {for (final r in latest.items) r.id};
      emit(
        latest.copyWith(
          items: [
            ...latest.items,
            ...page.items.where((r) => !known.contains(r.id)),
          ],
          total: page.total,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } on AppFailure catch (f) {
      final latest = state;
      if (isClosed ||
          generation != _generation ||
          latest is! ReservationLoaded) {
        return;
      }
      emit(latest.copyWith(isLoadingMore: false, loadMoreError: f.userMessage));
    }
  }

  /// Recherche client, appliquée sans appel réseau aux pages chargées.
  void setQuery(String query) {
    _query = query;
    final current = state;
    if (current is ReservationLoaded) emit(current.copyWith(query: query));
  }

  ReservationLoaded _loaded(ReservationPage page, {BookingStatsModel? stats}) {
    _page = page.page;
    return ReservationLoaded(
      page.items,
      stats: stats,
      query: _query,
      total: page.total,
      hasMore: page.hasMore,
    );
  }

  Future<ReservationPage> _fetch(int page) => _repository.getReservationPage(
    propertyId: options.propertyId,
    status: _status,
    page: page,
    perPage: options.perPage,
  );

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
