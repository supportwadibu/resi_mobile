import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/repositories/reservation_repository.dart';
import 'arrival_state.dart';

/// Arrivée d'un client au comptoir : il présente son QR (ou son PIN), le
/// propriétaire encaisse le reste éventuel, puis valide l'arrivée.
///
/// En ligne seulement, contrairement à l'arrivée depuis la fiche : retrouver
/// une réservation par son code et constater le paiement en ligne exigent le
/// serveur. Le serveur reste seul juge de la remise des clés — l'écran ne
/// fait que relayer ce qui la bloque.
class ArrivalCubit extends Cubit<ArrivalState> {
  ArrivalCubit(this._repository) : super(const ArrivalScanning());

  final ReservationRepository _repository;

  /// Code de la fiche ouverte, relu après un encaissement pour savoir si
  /// l'arrivée est débloquée.
  String? _code;

  /// Recherche en cours : la caméra lit le même QR plusieurs fois par
  /// seconde, et chaque lecture ne doit pas relancer la requête.
  bool _looking = false;

  Future<void> lookup(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty || _looking || state is! ArrivalScanning) return;
    _looking = true;
    emit(const ArrivalLookingUp());
    try {
      final arrival = await _repository.findArrival(trimmed);
      _code = trimmed;
      if (!isClosed) emit(ArrivalReady(arrival));
    } on AppFailure catch (f) {
      if (!isClosed) emit(ArrivalScanning(message: f.userMessage));
    } finally {
      _looking = false;
    }
  }

  /// Encaisse [amount] au comptoir puis relit la fiche.
  Future<void> collect(double amount) async {
    final current = state;
    final code = _code;
    if (current is! ArrivalReady || current.busy || code == null) return;
    if (amount <= 0) return;
    emit(current.copyWith(busy: true));
    try {
      await _repository.recordPayment(current.arrival.reservation.id, amount);
      final arrival = await _repository.findArrival(code);
      if (!isClosed) emit(ArrivalReady(arrival));
    } on AppFailure catch (f) {
      if (!isClosed) {
        emit(current.copyWith(busy: false, message: f.userMessage));
      }
    }
  }

  Future<void> checkIn() async {
    final current = state;
    if (current is! ArrivalReady || current.busy) return;
    emit(current.copyWith(busy: true));
    try {
      final reservation = await _repository.checkIn(
        current.arrival.reservation.id,
      );
      if (!isClosed) emit(ArrivalCompleted(reservation));
    } on AppFailure catch (f) {
      if (!isClosed) {
        emit(current.copyWith(busy: false, message: f.userMessage));
      }
    }
  }

  /// Retour au viseur, pour le client suivant.
  void reset() {
    _code = null;
    emit(const ArrivalScanning());
  }
}
