import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../features/clients/data/repositories/clients_repository.dart';
import '../../features/reservation/data/datasources/reservation_local_store.dart';
import '../../features/reservation/data/repositories/reservation_repository.dart';
import '../error/failures.dart';

/// Ce que la synchronisation vient de faire, pour l'affichage.
class SyncReport {
  const SyncReport({
    this.sent = 0,
    this.conflicts = 0,
    this.remaining = 0,
    this.failed = 0,
  });

  final int sent;

  /// Réservations refusées pour chevauchement : elles restent en base et
  /// attendent l'arbitrage du propriétaire.
  final int conflicts;

  final int remaining;
  final int failed;

  bool get hasWork => sent > 0 || conflicts > 0 || failed > 0;
}

/// Envoie les réservations saisies hors ligne dès que le réseau revient.
///
/// La file se vide **en série** : deux réservations sur le même bien doivent
/// s'ordonner, et les envoyer en parallèle rendrait l'issue indéterminée.
class SyncService {
  SyncService(
    this._store,
    this._reservations,
    this._clients,
    this._connectivity,
  );

  final ReservationLocalStore _store;
  final ReservationRepository _reservations;
  final ClientsRepository _clients;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Une synchronisation à la fois : le retour du réseau et une demande
  /// manuelle peuvent survenir en même temps, et deux passes concurrentes
  /// enverraient deux fois la même réservation.
  bool _running = false;

  /// Nombre de réservations en attente, pour un indicateur dans l'interface.
  final ValueNotifier<int> pendingCount = ValueNotifier(0);

  /// Nombre de conflits à arbitrer.
  final ValueNotifier<int> conflictCount = ValueNotifier(0);

  /// Commence à écouter le réseau et tente une première passe.
  Future<void> start() async {
    await refreshCounters();

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) unawaited(synchronize());
    });

    unawaited(synchronize());
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    pendingCount.dispose();
    conflictCount.dispose();
  }

  Future<void> refreshCounters() async {
    pendingCount.value = await _store.pendingCount();
    conflictCount.value = await _store.conflictCount();
  }

  /// Vide la file, une réservation après l'autre.
  Future<SyncReport> synchronize() async {
    if (_running) return const SyncReport();

    final results = await _connectivity.checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!online) return const SyncReport();

    _running = true;
    var sent = 0;
    var conflicts = 0;
    var failed = 0;

    try {
      final queue = await _store.getQueue();

      for (final booking in queue) {
        final outcome = await _send(booking);

        switch (outcome) {
          case _SendOutcome.sent:
            sent++;
          case _SendOutcome.conflict:
            conflicts++;
          case _SendOutcome.retry:
            failed++;
            // Le réseau vient de retomber : inutile d'insister sur le reste
            // de la file, la prochaine reconnexion la reprendra.
            if (!await _isOnline()) return _report(sent, conflicts, failed);
        }
      }
    } finally {
      _running = false;
      await refreshCounters();
    }

    return _report(sent, conflicts, failed);
  }

  Future<SyncReport> _report(int sent, int conflicts, int failed) async {
    return SyncReport(
      sent: sent,
      conflicts: conflicts,
      failed: failed,
      remaining: await _store.pendingCount(),
    );
  }

  Future<bool> _isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Envoie une réservation, en créant son client au passage si besoin.
  Future<_SendOutcome> _send(PendingBooking booking) async {
    try {
      final clientId = await _resolveClientId(booking);
      if (clientId == null) return _SendOutcome.retry;

      await _reservations.createOwnerBooking(
        propertyId: booking.propertyId,
        clientId: clientId,
        stayType: booking.stayType,
        checkInAt: booking.checkInAt,
        checkOutAt: booking.checkOutAt,
        receivedAmount: booking.receivedAmount,
        depositAmount: booking.depositAmount,
        message: booking.message,
        isCheckIn: booking.isCheckIn,
        // L'identifiant rend l'envoi rejouable : si la réponse s'est perdue
        // au premier essai, le serveur renvoie la réservation déjà créée au
        // lieu d'en produire une seconde.
        clientRequestId: booking.clientRequestId,
      );

      await _store.dequeue(booking.clientRequestId);
      return _SendOutcome.sent;
    } on AppFailure catch (failure) {
      return _handleFailure(booking, failure);
    }
  }

  /// Identifiant serveur du client, créé à la volée s'il ne l'est pas encore.
  Future<String?> _resolveClientId(PendingBooking booking) async {
    final remote = booking.remoteClientId;
    if (remote != null && remote.isNotEmpty) return remote;

    final localId = booking.localClientId;
    if (localId == null) return null;

    final pending = await _store.getPendingClient(localId);
    if (pending == null) return null;

    // Le client a pu être créé lors d'une passe précédente interrompue avant
    // l'envoi de la réservation.
    if (pending.remoteId != null && pending.remoteId!.isNotEmpty) {
      return pending.remoteId;
    }

    // Le serveur retourne la fiche existante si le numéro est déjà au carnet,
    // sans en créer une seconde : aucun doublon n'est possible.
    final created = await _clients.create(
      fullName: pending.fullName,
      phone: pending.phone,
      documentFrontPath: pending.documentFrontPath,
      documentBackPath: pending.documentBackPath,
    );

    await _store.linkClientRemoteId(localId, created.client.id);
    return created.client.id;
  }

  /// Décide du sort d'une réservation refusée.
  ///
  /// Un conflit de période est définitif tant que le propriétaire n'a pas
  /// tranché ; une panne réseau se réessaie. Dans les deux cas la réservation
  /// reste en base : elle porte de l'argent encaissé, la perdre serait pire
  /// que tout.
  Future<_SendOutcome> _handleFailure(
    PendingBooking booking,
    AppFailure failure,
  ) async {
    final isConflict = _looksLikeConflict(failure);

    await _store.markFailure(
      booking.clientRequestId,
      error: failure.userMessage,
      status: isConflict
          ? PendingSyncStatus.conflict
          : PendingSyncStatus.pending,
    );

    return isConflict ? _SendOutcome.conflict : _SendOutcome.retry;
  }

  /// Le serveur répond 409 sur un chevauchement de période.
  ///
  /// Le code HTTP fait foi plutôt que le texte du message, qui peut être
  /// traduit ou reformulé sans préavis.
  static bool _looksLikeConflict(AppFailure failure) =>
      failure.statusCode == 409;
}

enum _SendOutcome { sent, conflict, retry }
