import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../../../core/offline/offline_action_queue.dart';
import '../../../core/offline/pending_action.dart';
import '../../property/data/models/property_model.dart';
import '../data/models/reservation_model.dart';
import '../data/repositories/reservation_repository.dart';
import 'edit_reservation_state.dart';

/// Pilote la modification d'une réservation comptoir non terminée.
///
/// Distinct du formulaire de création : ni client à saisir, ni pièce. C'est le
/// serveur qui arbitre le chevauchement : hors réseau, la modification part
/// en file, et un conflit découvert à l'envoi remonte au propriétaire.
class EditReservationCubit extends Cubit<EditReservationState> {
  EditReservationCubit(
    this._repository,
    ReservationModel reservation, {
    OfflineActionQueue? queue,
  }) : _queue = queue,
       super(EditReservationState.from(reservation));

  final ReservationRepository _repository;

  /// File hors ligne. Sans elle, une panne réseau s'affiche comme un échec.
  final OfflineActionQueue? _queue;

  /// Grille du logement, connue une fois les biens chargés.
  ///
  /// Appelée aussi pour le logement d'origine : la réservation ne porte que le
  /// tarif journalier figé, pas les paliers, et le montant attendu se
  /// recalcule sur la grille **courante** — comme le fera le serveur.
  ///
  /// Un séjour complet est recalé sur l'heure de départ du logement : sa
  /// sortie ne se saisit plus, et une sortie héritée du décompte en 24h
  /// — 15h pour une entrée à 15h — serait facturée en départ tardif.
  void setProperty(PropertyModel property) {
    final policy = property.pricing.lateCheckoutPolicy;
    emit(
      state.copyWith(
        propertyId: property.id,
        dailyPrice: property.pricing.dailyPrice,
        priceTiers: PriceTierList.sorted(property.pricing.priceTiers),
        lateCheckoutPolicy: policy,
        checkOutAt: state.stayType == StayType.fullDay
            ? policy.checkOutFor(state.checkInAt, state.daysCount)
            : state.checkOutAt,
      ),
    );
  }

  void setStayType(StayType type) {
    emit(
      state.copyWith(
        stayType: type,
        checkOutAt: type == StayType.fullDay
            ? state.lateCheckoutPolicy.checkOutFor(
                state.checkInAt,
                state.daysCount,
              )
            : state.checkInAt.add(type.defaultDuration),
      ),
    );
  }

  /// Modifie la durée en nuits (pour séjour complet) : la sortie tombe à
  /// l'heure de départ du logement après la dernière nuit.
  void setDaysCount(int count) {
    if (count < 1) return;
    emit(
      state.copyWith(
        daysCount: count,
        checkOutAt: state.lateCheckoutPolicy.checkOutFor(
          state.checkInAt,
          count,
        ),
      ),
    );
  }

  /// Déplace l'entrée en gardant la durée : décaler un séjour de trois nuits
  /// ne doit pas le ramener à une nuit.
  void setCheckIn(DateTime value) {
    if (state.stayType == StayType.fullDay) {
      emit(
        state.copyWith(
          checkInAt: value,
          checkOutAt: state.lateCheckoutPolicy.checkOutFor(
            value,
            state.daysCount,
          ),
        ),
      );
      return;
    }
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

  void setCheckOut(DateTime value) {
    int newDays = state.daysCount;
    if (state.stayType == StayType.fullDay) {
      final calDiff = DateTime(value.year, value.month, value.day)
          .difference(
            DateTime(
              state.checkInAt.year,
              state.checkInAt.month,
              state.checkInAt.day,
            ),
          )
          .inDays;
      newDays = calDiff > 0 ? calDiff : 1;
    }
    emit(state.copyWith(checkOutAt: value, daysCount: newDays));
  }

  /// Prix convenu par unité : le total se recalcule avec les dates.
  void setAgreedUnitPrice(double? value) => emit(
    value == null
        ? state.copyWith(clearAgreedUnitPrice: true)
        : state.copyWith(agreedUnitPrice: value),
  );

  void setDepositAmount(double value) =>
      emit(state.copyWith(depositAmount: value));

  void setMessage(String value) => emit(state.copyWith(message: value));

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(state.copyWith(status: EditReservationStatus.submitting));

    final queue = _queue;
    if (queue != null && isLocalId(state.original.id)) return _enqueue(queue);

    try {
      final updated = await _repository.update(
        state.original.id,
        propertyId: state.propertyId,
        stayType: state.stayType,
        checkInAt: state.checkInAt,
        checkOutAt: state.checkOutAt,
        daysCount: state.stayType == StayType.fullDay ? state.daysCount : 1,
        agreedAmount: state.agreedAmount,
        agreedUnitPrice: state.agreedUnitPrice,
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

      if (queue != null && OfflineActionQueue.isNetworkFailure(f)) {
        return _enqueue(queue);
      }

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

  Future<void> _enqueue(OfflineActionQueue queue) async {
    await queue.enqueue(
      PendingActionType.bookingUpdate,
      targetRef: state.original.id,
      // Mêmes champs que `ReservationRepository.update` : la réservation part
      // entière, le serveur recalculant montant et chevauchement sur le tout.
      payload: {
        'property_id': state.propertyId,
        'stay_type': state.stayType.code,
        'check_in_at': state.checkInAt.toUtc().toIso8601String(),
        'check_out_at': state.checkOutAt.toUtc().toIso8601String(),
        'received_amount': ?state.agreedAmount,
        'agreed_unit_price': ?state.agreedUnitPrice,
        'deposit_amount': state.depositAmount,
        'message': state.message.trim().isEmpty ? null : state.message.trim(),
      },
    );
    if (!isClosed) {
      emit(state.copyWith(status: EditReservationStatus.success, queued: true));
    }
  }
}
