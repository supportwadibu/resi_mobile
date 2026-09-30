import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/models/client_model.dart';
import '../data/repositories/clients_repository.dart';
import 'client_detail_state.dart';

/// Fiche d'un client : coordonnées, cumuls et historique des séjours.
class ClientDetailCubit extends Cubit<ClientDetailState> {
  ClientDetailCubit(this._repository) : super(const ClientDetailInitial());

  final ClientsRepository _repository;

  /// Charge la fiche, puis son historique.
  ///
  /// La fiche connue est affichée sans attendre quand elle est fournie : elle
  /// vient de la liste du carnet, et le propriétaire doit pouvoir appeler son
  /// client sans patienter. Elle est ensuite remplacée par la version du
  /// serveur, seule à porter les URLs signées des pièces.
  Future<void> load(String id, {ClientModel? known}) async {
    if (known != null) {
      emit(ClientDetailLoaded(client: known, isHistoryLoading: true));
    } else {
      emit(const ClientDetailLoading());
    }

    try {
      final client = await _repository.getClient(id);
      if (isClosed) return;
      emit(ClientDetailLoaded(client: client, isHistoryLoading: true));
    } on AppFailure catch (failure) {
      if (isClosed) return;
      // Une fiche déjà affichée n'est pas effacée : le carnet en avait une
      // version utilisable, la perdre pour un réseau coupé serait une
      // régression visible.
      if (state case final ClientDetailLoaded loaded) {
        emit(loaded.copyWith(isHistoryLoading: false));
      } else {
        emit(ClientDetailError(failure.userMessage));
      }
      return;
    }

    await _loadHistory(id);
  }

  /// Recharge l'historique seul, après un échec.
  Future<void> retryHistory(String id) async {
    if (state case final ClientDetailLoaded loaded) {
      emit(loaded.copyWith(isHistoryLoading: true, clearHistoryError: true));
      await _loadHistory(id);
    }
  }

  Future<void> _loadHistory(String id) async {
    try {
      final history = await _repository.getClientHistory(id);
      if (isClosed) return;

      if (state case final ClientDetailLoaded loaded) {
        emit(
          loaded.copyWith(
            // Les cumuls servis avec l'historique priment sur ceux de la
            // fiche : celle-ci n'en porte qu'un cache, recalculé à partir des
            // mêmes séjours.
            client: loaded.client.copyWith(stats: history.stats),
            reservations: history.reservations,
            isHistoryLoading: false,
            clearHistoryError: true,
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (isClosed) return;
      if (state case final ClientDetailLoaded loaded) {
        emit(
          loaded.copyWith(
            isHistoryLoading: false,
            historyError: failure.userMessage,
          ),
        );
      }
    }
  }

  /// Enregistre les modifications de la fiche.
  ///
  /// Rend le message d'erreur à afficher, ou `null` si l'enregistrement a
  /// abouti — l'écran d'édition doit savoir s'il peut se refermer.
  Future<String?> save(
    String id, {
    String? fullName,
    String? phone,
    String? whatsapp,
    ClientIdDocumentType? idDocumentType,
    String? idDocumentNumber,
    ClientIdentity? identity,
    String? documentFrontPath,
    String? documentBackPath,
  }) async {
    if (state case final ClientDetailLoaded loaded) {
      emit(loaded.copyWith(isSaving: true));

      try {
        final updated = await _repository.update(
          id,
          fullName: fullName,
          phone: phone,
          whatsapp: whatsapp,
          idDocumentType: idDocumentType,
          idDocumentNumber: idDocumentNumber,
          identity: identity,
          documentFrontPath: documentFrontPath,
          documentBackPath: documentBackPath,
        );
        if (isClosed) return null;

        // La réponse de mise à jour ne porte pas les cumuls recalculés ; ceux
        // déjà affichés sont conservés plutôt que remis à zéro.
        emit(
          loaded.copyWith(
            client: updated.copyWith(stats: loaded.client.stats),
            isSaving: false,
          ),
        );
        return null;
      } on AppFailure catch (failure) {
        if (isClosed) return null;
        emit(loaded.copyWith(isSaving: false));
        return failure.userMessage;
      }
    }
    return null;
  }
}
