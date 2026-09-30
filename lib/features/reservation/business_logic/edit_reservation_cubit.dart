import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../property/data/models/property_model.dart';
import '../data/models/reservation_model.dart';
import '../data/repositories/reservation_repository.dart';
import 'edit_reservation_state.dart';

/// Pilote la modification d'une réservation comptoir non terminée.
///
/// Distinct du formulaire de création : ni client à saisir, ni pièce, ni file
/// hors ligne — la réservation existe déjà côté serveur, et c'est lui qui
/// arbitre le chevauchement.
class EditReservationCubit extends Cubit<EditReservationState> {
  EditReservationCubit(this._repository, ReservationModel reservation)
    : super(EditReservationState.from(reservation));

  final ReservationRepository _repository;

  /// Grille du logement, connue une fois les biens chargés.
  ///
  /// Appelée aussi pour le logement d'origine : la réservation ne porte que le
  /// tarif journalier figé, pas les paliers, et le montant attendu se
  /// recalcule sur la grille **courante** — comme le fera le serveur.
  void setProperty(PropertyModel property) {
    emit(
      state.copyWith(
        propertyId: property.id,
        dailyPrice: property.pricing.dailyPrice,
        priceTiers: PriceTierList.sorted(property.pricing.priceTiers),
      ),
    );
  }

  void setStayType(StayType type) {
    emit(
      state.copyWith(
        stayType: type,
        // Même règle qu'à la création : la sortie suit le type choisi.
        checkOutAt: state.checkInAt.add(type.defaultDuration),
      ),
    );
  }

  /// Déplace l'entrée en gardant la durée : décaler un séjour de trois jours
  /// ne doit pas le ramener à un jour.
  void setCheckIn(DateTime value) {
    final length = state.checkOutAt.difference(state.checkInAt);
    emit(
      state.copyWith(
        checkInAt: value,
        checkOutAt: value.add(
          length.isNegative ? state.stayType.defaultDuration : length,
        ),
      ),
    );
  }

  void setCheckOut(DateTime value) => emit(state.copyWith(checkOutAt: value));

  void setAgreedAmount(double? value) => emit(
    value == null
        ? state.copyWith(clearAgreedAmount: true)
        : state.copyWith(agreedAmount: value),
  );

  void setDepositAmount(double value) =>
      emit(state.copyWith(depositAmount: value));

  void setMessage(String value) => emit(state.copyWith(message: value));

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(status: EditReservationStatus.submitting));

    try {
      final updated = await _repository.update(
        state.original.id,
        propertyId: state.propertyId,
        stayType: state.stayType,
        checkInAt: state.checkInAt,
        checkOutAt: state.checkOutAt,
        agreedAmount: state.agreedAmount,
        depositAmount: state.depositAmount,
        message: state.message,
      );

      if (!isClosed) {
        emit(
          state.copyWith(
            status: EditReservationStatus.success,
            updated: updated,
          ),
        );
      }
    } on AppFailure catch (f) {
      if (isClosed) return;

      // Le `statusCode` distingue la cause, jamais le texte : 409 est un refus
      // métier — période prise, séjour clos entre-temps — à présenter tel
      // quel, le formulaire restant ouvert.
      emit(
        state.copyWith(
          status: f.statusCode == 409
              ? EditReservationStatus.conflict
              : EditReservationStatus.failure,
          errorMessage: f.userMessage,
        ),
      );
    }
  }
}
