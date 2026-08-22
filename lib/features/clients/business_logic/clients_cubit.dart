import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../reservation/data/datasources/reservation_local_store.dart';
import '../data/models/client_filter_model.dart';
import '../data/models/client_model.dart';
import '../data/repositories/clients_repository.dart';
import 'clients_state.dart';

/// Carnet de clients : liste, recherche et archivage.
class ClientsCubit extends Cubit<ClientsState> {
  ClientsCubit(this._repository, this._store) : super(const ClientsInitial());

  final ClientsRepository _repository;
  final ReservationLocalStore _store;

  /// La frappe ne doit pas déclencher une requête par caractère : la recherche
  /// part une fois la saisie reposée.
  static const _searchDebounce = Duration(milliseconds: 350);
  Timer? _debounce;

  int _page = 1;
  String _query = '';
  ClientFilter _filter = ClientFilter.all;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> load() async {
    emit(const ClientsLoading());
    await _fetchFirstPage();
  }

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(_searchDebounce, () {
      _query = query;
      _fetchFirstPage();
    });
  }

  void setFilter(ClientFilter filter) {
    _filter = filter;
    _fetchFirstPage();
  }

  /// Charge la page suivante et l'ajoute à la liste affichée.
  Future<void> loadMore() async {
    final current = state;
    if (current is! ClientsLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final page = await _repository.getClientPage(
        query: _query,
        status: _statusOf(_filter),
        page: _page + 1,
      );

      _page = page.page;
      if (!isClosed) {
        emit(
          current.copyWith(
            items: [...current.items, ...page.items],
            isLoadingMore: false,
            hasMore: page.hasMore,
          ),
        );
      }
    } on AppFailure catch (f) {
      // La page suivante a échoué : on garde la liste déjà affichée plutôt que
      // de la remplacer par une erreur pleine page.
      if (!isClosed) emit(current.copyWith(isLoadingMore: false));
      _lastLoadMoreError = f.userMessage;
    }
  }

  /// Message du dernier échec de pagination, à afficher discrètement.
  String? _lastLoadMoreError;
  String? get lastLoadMoreError => _lastLoadMoreError;

  /// Archive un client, ou le réactive.
  Future<void> setStatus(String id, ClientStatus status) async {
    final current = state;
    if (current is! ClientsLoaded) return;

    try {
      final updated = await _repository.update(id, status: status);

      if (isClosed) return;

      // Une fiche qui sort du filtre courant disparaît de la liste ; sinon
      // elle est remplacée sur place.
      final matchesFilter =
          _filter == ClientFilter.all || _statusOf(_filter) == updated.status;

      emit(
        current.copyWith(
          items: matchesFilter
              ? current.items
                    .map((c) => c.id == id ? updated : c)
                    .toList(growable: false)
              : current.items.where((c) => c.id != id).toList(growable: false),
        ),
      );
    } on AppFailure catch (f) {
      if (!isClosed) emit(ClientsError(f.userMessage));
    }
  }

  Future<void> _fetchFirstPage() async {
    try {
      final page = await _repository.getClientPage(
        query: _query,
        status: _statusOf(_filter),
      );

      _page = page.page;

      // Le carnet est mis en cache à chaque lecture réussie : c'est lui qui
      // alimente le bottomsheet et le dédoublonnage quand le réseau manque.
      await _store.upsertClients(page.items);

      if (!isClosed) {
        emit(
          ClientsLoaded(
            items: page.items,
            query: _query,
            filter: _filter,
            hasMore: page.hasMore,
          ),
        );
      }
    } on AppFailure catch (f) {
      // Hors réseau, le carnet en cache prend le relais plutôt que d'afficher
      // une erreur sur un écran que l'appareil sait remplir.
      final cached = await _store.searchClients(
        query: _query,
        status: _statusOf(_filter),
      );

      if (isClosed) return;

      emit(
        cached.isEmpty
            ? ClientsError(f.userMessage)
            : ClientsLoaded(
                items: cached,
                query: _query,
                filter: _filter,
                hasMore: false,
              ),
      );
    }
  }

  /// Le filtre « Tous » ne contraint pas le statut côté serveur.
  static ClientStatus? _statusOf(ClientFilter filter) => switch (filter) {
    ClientFilter.all => null,
    ClientFilter.active => ClientStatus.active,
    ClientFilter.archived => ClientStatus.archived,
  };
}
