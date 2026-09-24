import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/repositories/reservation_repository.dart';
import 'stay_extension_state.dart';

/// Pilote la prolongation d'un séjour comptoir.
///
/// Séparé du cubit de liste : un échec de prolongation ne doit pas vider les
/// réservations affichées derrière.
class StayExtensionCubit extends Cubit<StayExtensionState> {
  StayExtensionCubit(this._repository) : super(const StayExtensionIdle());

  final ReservationRepository _repository;

  /// Repousse la sortie d'un séjour.
  ///
  /// [receivedAmount] est le montant renégocié avec le client ; à défaut, le
  /// serveur réajuste sur le nouveau montant attendu — laisser l'ancien
  /// montant ferait apparaître un impayé qui n'existe pas.
  ///
  /// La prolongation n'est pas mise en file hors réseau, contrairement à la
  /// création : elle porte sur un séjour que le serveur connaît déjà, et deux
  /// prolongations concurrentes du même séjour ne s'ordonneraient pas sans
  /// arbitrage. Un échec réseau se réessaie donc à la main.
  Future<void> submit({
    required String bookingId,
    required DateTime checkOutAt,
    num? receivedAmount,
  }) async {
    emit(const StayExtensionSubmitting());

    try {
      final reservation = await _repository.extend(
        bookingId,
        checkOutAt: checkOutAt,
        receivedAmount: receivedAmount,
      );

      if (!isClosed) emit(StayExtensionSuccess(reservation));
    } on AppFailure catch (f) {
      if (isClosed) return;

      // Le `statusCode` distingue la cause, jamais le texte du message : 409
      // est un refus métier à présenter tel quel, pas une panne à réessayer.
      //
      // Le serveur en renvoie trois — période déjà réservée, séjour clôturé,
      // réservation annulée — que `AppFailure` ne sépare pas, ne portant pas
      // le `code` métier. Sans conséquence ici : le message du serveur est
      // propagé tel quel, et les trois se présentent de la même façon. Les
      // distinguer supposerait d’exposer `code` sur `AppFailure`, ce qui
      // touche tous les appelants.
      emit(
        f.statusCode == 409
            ? StayExtensionConflict(f.userMessage)
            : StayExtensionFailure(f.userMessage),
      );
    }
  }
}
