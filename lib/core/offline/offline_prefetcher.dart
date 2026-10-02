import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/clients/business_logic/client_detail_cubit.dart';
import '../../features/clients/business_logic/clients_cubit.dart';
import '../../features/clients/business_logic/clients_state.dart';
import '../../features/expense/business_logic/expense_cubit.dart';
import '../../features/expense/business_logic/expense_state.dart';
import '../../features/home/business_logic/home_stats_cubit.dart';
import '../../features/property/business_logic/property_cubit.dart';
import '../../features/property/business_logic/property_state.dart';
import '../../features/reservation/business_logic/reservation_cubit.dart';
import '../../features/reservation/business_logic/reservation_state.dart';
import '../../features/reservation/data/models/reservation_model.dart';
import '../../features/residence/business_logic/residence_cubit.dart';
import '../../features/residence/business_logic/residence_detail_cubit.dart';
import '../../features/residence/business_logic/residence_state.dart';
import '../../features/stats/business_logic/dashboard_cubit.dart';
import '../../features/stats/business_logic/finance_cubit.dart';
import '../../features/subscription/presentation/widgets/plan_gate.dart';
import '../di/service_locator.dart';
import 'offline_status.dart';

/// Remplit le cache des lectures, pour que le propriétaire retrouve hors ligne
/// des écrans qu'il n'a pas ouverts dans la session.
///
/// Le cache ne sert une lecture que si l'écran la redemande **à l'identique**
/// — mêmes paramètres, même taille de page. Plutôt que de recopier ces
/// paramètres ici, où ils divergeraient au premier changement d'écran, le
/// préchargement rejoue le `load()` des cubits d'écran eux-mêmes, puis les
/// ferme : ce qu'il garde est exactement ce que l'écran demandera.
///
/// En série, et interrompu dès que le réseau tombe : un préchargement ne doit
/// ni saturer une connexion lente ni disputer la bande passante à l'écran.
class OfflinePrefetcher {
  OfflinePrefetcher({
    required Future<bool> Function() isOnline,
    required Future<bool> Function() isSignedIn,
    this.minInterval = const Duration(minutes: 15),
  }) : _isOnline = isOnline,
       _isSignedIn = isSignedIn;

  final Future<bool> Function() _isOnline;
  final Future<bool> Function() _isSignedIn;

  /// Écart minimal entre deux passes non forcées : chaque retour du réseau en
  /// déclenche une, et un réseau qui papillote rechargerait tout le parc à
  /// chaque reprise sur un forfait de données payé au mégaoctet.
  final Duration minInterval;

  /// Plafonds par liste : au-delà, la donnée sert rarement hors ligne, et la
  /// charger coûterait plus qu'elle ne rapporte.
  static const _maxPages = 10;
  static const _maxDetails = 40;

  bool _running = false;
  DateTime? _lastRun;

  @visibleForTesting
  bool get isRunning => _running;

  Future<void> run({bool force = false}) async {
    if (_running) return;
    final last = _lastRun;
    if (!force && last != null && DateTime.now().difference(last) < minInterval) {
      return;
    }

    _running = true;
    try {
      if (!await _isSignedIn() || !await _isOnline()) return;
      _lastRun = DateTime.now();
      await _prefetch();
    } catch (e) {
      // Un préchargement n'est jamais une erreur pour l'utilisateur : l'écran
      // retentera sa propre lecture.
      debugPrint('Préchargement hors ligne interrompu : $e');
    } finally {
      _running = false;
    }
  }

  Future<void> _prefetch() async {
    final properties = await _warm(sl<PropertyCubit>(), (c) => c.load());
    final propertyIds = switch (properties) {
      PropertyLoaded(:final items) => items.map((p) => p.id).toList(),
      _ => const <String>[],
    };

    if (!await _step()) return;
    await _warm(sl<HomeStatsCubit>(), (c) => c.load());

    // Aperçu de l'onglet, puis liste complète et ses filtres de statut.
    if (!await _step()) return;
    await _warm(
      sl<ReservationCubit>(param1: ReservationListOptions.recent),
      (c) => c.load(),
    );
    if (!await _step()) return;
    await _warm(sl<ReservationCubit>(), (c) async {
      await c.load();
      await _drain(c, (s) => s is ReservationLoaded && s.hasMore, c.loadMore);
    });
    for (final status in ReservationStatus.values) {
      if (!await _step()) return;
      await _warm(sl<ReservationCubit>(), (c) => c.setStatus(status));
    }

    // Séjours de chaque bien, pour sa fiche.
    for (final id in propertyIds.take(_maxDetails)) {
      if (!await _step()) return;
      await _warm(
        sl<ReservationCubit>(param1: ReservationListOptions(propertyId: id)),
        (c) => c.load(),
      );
    }

    if (!await _step()) return;
    final clients = await _warm(sl<ClientsCubit>(), (c) async {
      await c.load();
      await _drain(c, (s) => s is ClientsLoaded && s.hasMore, c.loadMore);
    });
    final known = switch (clients) {
      ClientsLoaded(:final items) => items.take(_maxDetails).toList(),
      _ => const [],
    };
    for (final client in known) {
      if (!await _step()) return;
      await _warm(
        sl<ClientDetailCubit>(),
        (c) => c.load(client.id, known: client),
      );
    }

    if (!await _step()) return;
    final residences = await _warm(sl<ResidenceCubit>(), (c) => c.load());
    final residenceIds = switch (residences) {
      ResidenceLoaded(:final items) => items.map((r) => r.id).toList(),
      _ => const <String>[],
    };
    for (final id in residenceIds.take(_maxDetails)) {
      if (!await _step()) return;
      await _warm(sl<ResidenceDetailCubit>(), (c) => c.load(id));
    }

    // Écrans du forfait complet : les lire sans y avoir droit déclencherait un
    // refus de l'API, et le signal de forfait qui va avec.
    if (!hasFullPlan()) return;
    if (!await _step()) return;
    await _warm(sl<DashboardCubit>(), (c) => c.load());
    if (!await _step()) return;
    await _warm(sl<FinanceCubit>(), (c) => c.load());
    if (!await _step()) return;
    await _warm(sl<ExpenseCubit>(), (c) async {
      await c.load();
      await _drain(c, (s) => s is ExpenseLoaded && s.hasMore, c.loadMore);
    });
  }

  /// Le réseau tient-il toujours ? Sinon la passe s'arrête là.
  ///
  /// La connectivité seule ne suffit pas : un Wi-Fi sans Internet l'annonce,
  /// et chaque lecture retomberait sur le cache après son délai. Une lecture
  /// servie depuis le cache trahit la panne, et rien ne sert alors de
  /// continuer.
  Future<bool> _step() async =>
      sl<OfflineStatus>().value == null && await _isOnline();

  /// Rejoue [action] sur [cubit], le ferme, et rend son dernier état.
  Future<S> _warm<C extends Cubit<S>, S>(
    C cubit,
    Future<void> Function(C cubit) action,
  ) async {
    try {
      await action(cubit);
      return cubit.state;
    } finally {
      await cubit.close();
    }
  }

  /// Charge les pages suivantes tant qu'il en reste, dans la limite fixée.
  Future<void> _drain<S>(
    Cubit<S> cubit,
    bool Function(S state) hasMore,
    Future<void> Function() loadMore,
  ) async {
    for (var page = 1; page < _maxPages; page++) {
      if (!hasMore(cubit.state) || !await _isOnline()) return;
      await loadMore();
    }
  }
}
