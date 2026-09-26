import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../features/clients/data/models/client_creation_result.dart';
import '../../features/clients/data/repositories/clients_repository.dart';
import '../../features/reservation/data/datasources/reservation_local_store.dart';
import '../../features/reservation/data/repositories/reservation_repository.dart';
import '../error/failures.dart';

/// Codes d'un refus que rejouer ne résoudra jamais.
///
/// `out_of_scope` : le logement a quitté le périmètre du gérant entre la saisie
/// et l'envoi. `manager_not_assigned` : son affectation a été suspendue.
/// `client_out_of_scope` : la fiche du client existe hors de son périmètre, le
/// serveur l'accuse sans la livrer et aucun identifiant ne peut être rattaché.
/// Dans les trois cas le serveur refusera identiquement à chaque tentative, et
/// la saisie resterait en tête de file à bloquer tout ce qui suit.
const _definitiveCodes = <String>{
  'out_of_scope',
  'manager_not_assigned',
  'client_out_of_scope',
};

/// Ce refus doit-il retirer la saisie de la file plutôt que d'être rejoué ?
///
/// Le code prime sur le statut : un 403 dont on ne reconnaît pas le code peut
/// être transitoire — un jeton expiré que l'interceptor rafraîchira. Supprimer
/// la saisie perdrait le travail du gérant, ce qu'aucune reprise ne rattrape.
bool isDefinitiveRejection(int? statusCode, String? code) {
  if (statusCode != 403) return false;
  if (code == null) return false;
  return _definitiveCodes.contains(code);
}

/// Sort réservé à une réservation que le serveur vient de refuser.
enum FailureDisposition {
  /// Retirée de la file : la rejouer donnerait le même refus, indéfiniment.
  rejected,

  /// Gardée en base, hors file active, en attente d'arbitrage.
  conflict,

  /// Remise en file : la cause est transitoire.
  retry,
}

/// Décide du sort d'une réservation refusée, sur le seul couple statut + code.
///
/// Extraite du service pour être éprouvée sans base ni réseau : c'est la
/// décision dont dépend le déblocage de la file, et la tester au travers de
/// SQLite reviendrait à ne pas la tester du tout.
FailureDisposition classifyFailure(AppFailure failure) {
  if (isDefinitiveRejection(failure.statusCode, failure.code)) {
    return FailureDisposition.rejected;
  }

  // Abonnement échu pendant la coupure : la saisie reste en file. Le refus
  // cessera dès que le propriétaire aura payé, et l'en sortir comme conflit
  // lui ferait arbitrer une réservation que rien n'oppose à une autre.
  if (failure.isSubscriptionRequired || failure.isPlanUpgradeRequired) {
    return FailureDisposition.retry;
  }

  // Passé ce point, plus rien n'est rejouable en l'état : un chevauchement
  // (409) comme un refus de forme ou de droits (4xx) passent en « conflit »,
  // seul état qui remonte la saisie au propriétaire pour arbitrage.
  //
  // Aucune saisie n'est jamais détruite, quelle que soit la branche : elles
  // portent toutes de l'argent encaissé au comptoir.
  final isBlocking =
      _looksLikeConflict(failure) || _isPermanentRejection(failure);

  return isBlocking ? FailureDisposition.conflict : FailureDisposition.retry;
}

/// Le serveur répond 409 sur un chevauchement de période.
///
/// Le code HTTP fait foi plutôt que le texte du message, qui peut être
/// traduit ou reformulé sans préavis.
bool _looksLikeConflict(AppFailure failure) => failure.statusCode == 409;

/// Refus définitif : rejouer la même requête produirait le même refus.
///
/// Une réservation refusée pour sa forme (422) ou ses droits (401/403) ne
/// doit pas boucler en file : sans cette sortie, elle repartait à chaque
/// reconnexion, indéfiniment. Elle reste en base — elle porte de l'argent
/// encaissé — mais passe en conflit, à arbitrer par le propriétaire.
bool _isPermanentRejection(AppFailure failure) {
  final code = failure.statusCode;
  if (code == null) return false;
  return code >= 400 && code < 500 && code != 408 && code != 429;
}

/// Ce que la synchronisation vient de faire, pour l'affichage.
class SyncReport {
  const SyncReport({
    this.sent = 0,
    this.conflicts = 0,
    this.rejected = 0,
    this.remaining = 0,
    this.failed = 0,
  });

  final int sent;

  /// Réservations refusées pour chevauchement : elles restent en base et
  /// attendent l'arbitrage du propriétaire.
  final int conflicts;

  /// Réservations retirées de la file sur un refus définitif du serveur.
  ///
  /// Distinct de [conflicts] : un conflit s'arbitre — le propriétaire tranche
  /// qui occupe le logement — tandis qu'un rejet se constate, le gérant n'a
  /// plus le logement dans son périmètre et rien ne lui rendra.
  final int rejected;

  final int remaining;
  final int failed;

  bool get hasWork => sent > 0 || conflicts > 0 || rejected > 0 || failed > 0;
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

  /// Nombre de saisies définitivement refusées, conservées pour consultation.
  final ValueNotifier<int> rejectedCount = ValueNotifier(0);

  /// Dernière synchronisation ayant réellement transmis quelque chose.
  ///
  /// Le service tourne sans `BuildContext` — il est démarré au `bootstrap` —
  /// et ne peut donc pas afficher lui-même de message. Il publie son rapport,
  /// et l'écran qui l'observe s'en charge. Le bandeau d'attente disparaît
  /// silencieusement quand la file se vide : sans cette annonce, le
  /// propriétaire ne sait jamais que ses saisies sont bien parties.
  final ValueNotifier<SyncReport?> lastReport = ValueNotifier(null);

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
    rejectedCount.dispose();
    lastReport.dispose();
  }

  Future<void> refreshCounters() async {
    pendingCount.value = await _store.pendingCount();
    conflictCount.value = await _store.conflictCount();
    rejectedCount.value = await _store.rejectedCount();
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
    var rejected = 0;
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
          case _SendOutcome.rejected:
            // La saisie vient de quitter la file : la passe continue, c'est
            // précisément ce que ce retrait débloque.
            rejected++;
          case _SendOutcome.retry:
            failed++;
            // Le réseau vient de retomber : inutile d'insister sur le reste
            // de la file, la prochaine reconnexion la reprendra.
            if (!await _isOnline()) {
              return _report(sent, conflicts, rejected, failed);
            }
        }
      }
    } finally {
      _running = false;
      await refreshCounters();
    }

    return _report(sent, conflicts, rejected, failed);
  }

  Future<SyncReport> _report(
    int sent,
    int conflicts,
    int rejected,
    int failed,
  ) async {
    final report = SyncReport(
      sent: sent,
      conflicts: conflicts,
      rejected: rejected,
      failed: failed,
      remaining: await _store.pendingCount(),
    );

    // Une passe qui n'a rien fait — file vide, ou réseau toujours absent — ne
    // vaut pas d'être annoncée : la synchronisation se déclenche seule à
    // chaque retour de connexion, et signaler chacune deviendrait du bruit.
    if (report.hasWork) lastReport.value = report;

    return report;
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
        referrerName: booking.referrerName,
        referrerPhone: booking.referrerPhone,
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

    final client = created.client;
    if (client == null) {
      // La fiche existe hors du périmètre du gérant : le serveur l'accuse sans
      // la livrer, et il n'y a aucun identifiant à rattacher.
      //
      // Levé en 403 plutôt que rendu `null` : `null` vaut ici « à réessayer »,
      // et la réservation repartirait à chaque reconnexion sur un refus qui ne
      // bougera pas, bloquant toute la file derrière elle. Le 403 la classe en
      // refus définitif — retirée de la file, signalée au gérant, conservée en
      // base parce qu'elle porte de l'argent encaissé.
      throw AppFailure.forbidden(
        message: clientOutOfScopeMessage,
        code: 'client_out_of_scope',
      );
    }

    await _store.linkClientRemoteId(localId, client.id);
    return client.id;
  }

  /// Décide du sort d'une réservation refusée, et l'applique à la base.
  ///
  /// Un conflit de période est définitif tant que le propriétaire n'a pas
  /// tranché ; une panne réseau se réessaie. Dans ces deux cas la réservation
  /// reste en base : elle porte de l'argent encaissé, la perdre serait pire
  /// que tout. Seul un refus de périmètre la retire, parce que la garder
  /// bloquerait tout ce qui la suit dans la file.
  ///
  /// Exposée aux tests : la classification seule ne dit rien de ce qui est
  /// réellement écrit en base, et c'est ce retrait — non la valeur rendue —
  /// qui débloque la file.
  @visibleForTesting
  Future<void> handleFailureForTest(
    PendingBooking booking,
    AppFailure failure,
  ) => _handleFailure(booking, failure);

  Future<_SendOutcome> _handleFailure(
    PendingBooking booking,
    AppFailure failure,
  ) async {
    switch (classifyFailure(failure)) {
      case FailureDisposition.rejected:
        // Sortie de la file, et signalée : le gérant doit en référer au
        // propriétaire. La laisser en attente ferait échouer toute la file
        // derrière elle.
        //
        // Marquée et non supprimée : la saisie porte de l'argent encaissé au
        // comptoir. `getQueue()` ne sert que les `pending`, donc ce statut
        // suffit à l'écarter des envois sans rien détruire.
        await _store.markFailure(
          booking.clientRequestId,
          error: failure.userMessage,
          status: PendingSyncStatus.rejected,
        );
        return _SendOutcome.rejected;

      case FailureDisposition.conflict:
        await _store.markFailure(
          booking.clientRequestId,
          error: failure.userMessage,
          status: PendingSyncStatus.conflict,
        );
        return _SendOutcome.conflict;

      case FailureDisposition.retry:
        await _store.markFailure(
          booking.clientRequestId,
          error: failure.userMessage,
          status: PendingSyncStatus.pending,
        );
        return _SendOutcome.retry;
    }
  }
}

enum _SendOutcome { sent, conflict, rejected, retry }
