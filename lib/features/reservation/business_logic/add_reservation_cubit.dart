import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../clients/data/models/client_model.dart';
import '../../clients/data/repositories/clients_repository.dart';
import '../data/datasources/reservation_local_store.dart';
import '../data/models/occupied_period_model.dart';
import '../data/models/reservation_model.dart';
import '../data/repositories/reservation_repository.dart';
import 'add_reservation_state.dart';

/// Pilote l'enregistrement d'une réservation prise au comptoir.
///
/// Le client est soit choisi au carnet, soit saisi puis créé au moment de
/// l'envoi. Les deux chemins convergent : la réservation a besoin d'un
/// identifiant de fiche.
class AddReservationCubit extends Cubit<AddReservationState> {
  AddReservationCubit(
    this._reservations,
    this._clients,
    this._store,
    this._connectivity, {
    required ReservationMode mode,
  }) : super(
         AddReservationState(
           mode: mode,
           // Un check-in enregistre une arrivée qui a lieu maintenant : la
           // date n'est pas à choisir.
           checkInAt: mode == ReservationMode.checkIn ? DateTime.now() : null,
         ),
       );

  final ReservationRepository _reservations;
  final ClientsRepository _clients;
  final ReservationLocalStore _store;
  final Connectivity _connectivity;

  /// La recherche par numéro ne doit pas partir à chaque caractère.
  static const _lookupDebounce = Duration(milliseconds: 500);
  Timer? _lookupTimer;

  /// Périodes déjà prises sur le bien choisi, pour prévenir le conflit avant
  /// l'envoi plutôt qu'après.
  List<OccupiedPeriodModel> _occupied = const [];

  /// Identifiant d'idempotence, tiré une seule fois par formulaire.
  ///
  /// Conservé entre deux tentatives : si le premier envoi a abouti côté
  /// serveur mais que la réponse s'est perdue, le second renvoie la
  /// réservation déjà créée au lieu d'en produire une seconde.
  late final String _requestId = _generateRequestId();

  @override
  Future<void> close() {
    _lookupTimer?.cancel();
    return super.close();
  }

  // ── Client ────────────────────────────────────────────────────────────────

  /// Retient le client choisi au carnet et efface la saisie manuelle.
  void selectClient(ClientModel client) {
    _lookupTimer?.cancel();
    emit(
      state.copyWith(
        selectedClient: client,
        fullName: client.fullName,
        phone: client.phone,
        clearDuplicate: true,
        clearError: true,
      ),
    );
  }

  /// Repasse en saisie manuelle, en conservant ce qui est déjà tapé.
  void clearSelectedClient() {
    emit(state.copyWith(clearSelectedClient: true, clearDuplicate: true));
  }

  void setFullName(String value) => emit(state.copyWith(fullName: value));

  /// Enregistre le numéro et cherche une fiche existante.
  ///
  /// Le téléphone identifie le client : proposer la fiche trouvée évite un
  /// doublon au carnet et garde justes ses statistiques de séjour.
  void setPhone(String value) {
    emit(state.copyWith(phone: value, clearDuplicate: true));

    _lookupTimer?.cancel();
    if (state.selectedClient != null) return;
    if (value.trim().length < 8) return;

    _lookupTimer = Timer(_lookupDebounce, () => _lookupPhone(value));
  }

  Future<void> _lookupPhone(String phone) async {
    emit(state.copyWith(isLookingUpPhone: true));

    try {
      final result = await _clients.lookupByPhone(phone);
      if (isClosed) return;

      emit(
        state.copyWith(
          isLookingUpPhone: false,
          duplicateClient: result.exists ? result.client : null,
          clearDuplicate: !result.exists,
        ),
      );
    } on AppFailure {
      // Hors réseau, le carnet en cache prend le relais : le propriétaire
      // doit pouvoir retrouver un habitué même sans connexion.
      final cached = await _store.findClientByPhone(phone);
      if (isClosed) return;

      emit(
        state.copyWith(
          isLookingUpPhone: false,
          duplicateClient: cached,
          clearDuplicate: cached == null,
        ),
      );
    }
  }

  /// Écarte la fiche proposée : le propriétaire veut créer un nouveau client.
  void dismissDuplicate() => emit(state.copyWith(clearDuplicate: true));

  void setDocumentFront(String? path) => emit(
    path == null
        ? state.copyWith(clearDocumentFront: true)
        : state.copyWith(documentFrontPath: path),
  );

  void setDocumentBack(String? path) => emit(
    path == null
        ? state.copyWith(clearDocumentBack: true)
        : state.copyWith(documentBackPath: path),
  );

  // ── Séjour ────────────────────────────────────────────────────────────────

  /// Choisit le bien et charge ses périodes déjà réservées.
  Future<void> setProperty(String propertyId, {required double dailyPrice}) async {
    emit(
      state.copyWith(
        propertyId: propertyId,
        dailyPrice: dailyPrice,
        clearConflict: true,
      ),
    );

    try {
      _occupied = await _reservations.getAvailability(propertyId: propertyId);
      // Le cache alimente la saisie hors réseau : sans lui, le formulaire ne
      // saurait plus quelles dates sont prises.
      await _store.replaceBookingsForProperty(propertyId, _occupied);
    } on AppFailure {
      // Hors réseau, on se rabat sur ce que l'appareil connaît — y compris
      // les réservations encore en file, qui immobilisent le bien tout autant.
      _occupied = await _store.getOccupiedPeriods(propertyId);
    }

    if (!isClosed) _revalidateDates();
  }

  void setStayType(StayType type) {
    final checkIn = state.checkInAt;
    emit(
      state.copyWith(
        stayType: type,
        // La sortie suit le type choisi tant que le propriétaire ne l'a pas
        // fixée lui-même.
        checkOutAt: checkIn?.add(type.defaultDuration),
      ),
    );
    _revalidateDates();
  }

  void setCheckIn(DateTime value) {
    emit(
      state.copyWith(
        checkInAt: value,
        checkOutAt: value.add(state.stayType.defaultDuration),
      ),
    );
    _revalidateDates();
  }

  void setCheckOut(DateTime value) {
    emit(state.copyWith(checkOutAt: value));
    _revalidateDates();
  }

  // ── Montants ──────────────────────────────────────────────────────────────

  void setReceivedAmount(double? value) => emit(
    value == null
        ? state.copyWith(clearReceivedAmount: true)
        : state.copyWith(receivedAmount: value),
  );

  void setDepositAmount(double value) =>
      emit(state.copyWith(depositAmount: value));

  void setMessage(String value) => emit(state.copyWith(message: value));

  // ── Envoi ─────────────────────────────────────────────────────────────────

  /// Enregistre la réservation, en créant le client au passage si besoin.
  Future<void> submit() async {
    if (!state.isValid || state.status == AddReservationStatus.submitting) {
      return;
    }

    emit(
      state.copyWith(
        status: AddReservationStatus.submitting,
        clearError: true,
      ),
    );

    // Sans réseau, la réservation part en file plutôt que d'échouer : au
    // comptoir le client est là et l'argent encaissé, refuser la saisie
    // reviendrait à perdre la vente.
    if (!await _isOnline()) {
      await _enqueue();
      return;
    }

    try {
      final clientId = await _resolveClientId();
      if (isClosed) return;

      final reservation = await _reservations.createOwnerBooking(
        propertyId: state.propertyId!,
        clientId: clientId,
        stayType: state.stayType,
        checkInAt: state.checkInAt!,
        checkOutAt: state.checkOutAt,
        receivedAmount: state.effectiveAmount,
        depositAmount: state.depositAmount,
        message: state.message,
        isCheckIn: state.mode == ReservationMode.checkIn,
        clientRequestId: _requestId,
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            status: AddReservationStatus.success,
            createdReservation: reservation,
          ),
        );
      }
    } on AppFailure catch (f) {
      if (isClosed) return;

      // Le réseau a lâché en cours d'envoi : la saisie rejoint la file au
      // lieu d'être perdue. Un refus métier, lui, doit remonter au
      // propriétaire — le rejouer ne changerait rien.
      if (_isNetworkFailure(f)) {
        await _enqueue();
        return;
      }

      emit(
        state.copyWith(
          status: AddReservationStatus.failure,
          errorMessage: f.userMessage,
        ),
      );
    }
  }

  /// Met la réservation en file, avec son client s'il est nouveau.
  Future<void> _enqueue() async {
    final selected = state.selectedClient;
    final localClientId = selected == null ? 'local-$_requestId' : null;

    try {
      await _store.enqueueBooking(
        booking: PendingBooking(
          clientRequestId: _requestId,
          localClientId: localClientId,
          remoteClientId: selected?.id,
          propertyId: state.propertyId!,
          stayType: state.stayType,
          checkInAt: state.checkInAt!,
          checkOutAt: state.checkOutAt,
          receivedAmount: state.effectiveAmount,
          depositAmount: state.depositAmount,
          message: state.message,
          isCheckIn: state.mode == ReservationMode.checkIn,
          createdAt: DateTime.now(),
        ),
        newClient: localClientId == null
            ? null
            : PendingClient(
                localId: localClientId,
                fullName: state.fullName.trim(),
                phone: state.phone.trim(),
                documentFrontPath: state.documentFrontPath,
                documentBackPath: state.documentBackPath,
              ),
      );

      if (!isClosed) {
        emit(state.copyWith(status: AddReservationStatus.queued));
      }
    } catch (e) {
      // L'écriture locale a échoué : il n'y a plus de filet, il faut le dire.
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AddReservationStatus.failure,
            errorMessage:
                'Impossible d’enregistrer la réservation sur l’appareil.',
          ),
        );
      }
    }
  }

  Future<bool> _isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Panne de transport, par opposition à un refus métier du serveur.
  ///
  /// Sans code HTTP, la requête n'a jamais abouti : elle est rejouable.
  static bool _isNetworkFailure(AppFailure failure) =>
      failure.statusCode == null;

  /// Identifiant de la fiche à rattacher à la réservation.
  ///
  /// Le serveur retourne la fiche existante si le numéro est déjà au carnet,
  /// sans en créer une seconde : aucun doublon n'est possible même si la
  /// recherche pendant la saisie n'a rien vu.
  Future<String> _resolveClientId() async {
    final selected = state.selectedClient;
    if (selected != null) return selected.id;

    final created = await _clients.create(
      fullName: state.fullName.trim(),
      phone: state.phone.trim(),
      documentFrontPath: state.documentFrontPath,
      documentBackPath: state.documentBackPath,
    );

    return created.client.id;
  }

  /// Signale un chevauchement avec une réservation connue.
  ///
  /// Contrôle de confort : la liste peut être périmée, et le serveur reste
  /// l'autorité. Il évite au propriétaire de tout saisir pour rien.
  void _revalidateDates() {
    final start = state.checkInAt;
    final end = state.checkOutAt ?? start?.add(state.stayType.defaultDuration);

    if (start == null || end == null) {
      emit(state.copyWith(clearConflict: true));
      return;
    }

    if (!end.isAfter(start)) {
      emit(
        state.copyWith(
          occupiedConflict: 'La sortie doit être après l’entrée.',
        ),
      );
      return;
    }

    for (final period in _occupied) {
      if (!period.status.isActive) continue;
      if (period.overlaps(start, end)) {
        final who = period.clientName;
        emit(
          state.copyWith(
            occupiedConflict: who == null
                ? 'Ce bien est déjà réservé sur cette période.'
                : 'Déjà réservé sur cette période par $who.',
          ),
        );
        return;
      }
    }

    emit(state.copyWith(clearConflict: true));
  }

  /// Identifiant aléatoire, suffisant pour distinguer deux envois du même
  /// appareil. La collision n'aurait de portée qu'entre deux formulaires du
  /// même propriétaire à la même milliseconde.
  static String _generateRequestId() {
    final random = Random();
    final suffix = List.generate(
      8,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    return '${DateTime.now().microsecondsSinceEpoch}-$suffix';
  }
}
