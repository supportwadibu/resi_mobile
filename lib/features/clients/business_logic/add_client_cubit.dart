import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/models/client_creation_result.dart';
import '../data/models/identity_document_model.dart';
import '../data/repositories/clients_repository.dart';
import '../data/models/client_model.dart';
import 'add_client_state.dart';

/// Enregistre un client au carnet, hors réservation.
///
/// Ouvert au forfait 3 000 F : c'est de l'enregistrement. Les pièces restent
/// facultatives, comme au comptoir — un client peut ne pas avoir la sienne,
/// et la fiche se complète plus tard.
class AddClientCubit extends Cubit<AddClientState> {
  AddClientCubit(this._clients) : super(const AddClientState());

  final ClientsRepository _clients;

  void setFullName(String value) => emit(state.copyWith(fullName: value));

  void setPhone(String value) => emit(state.copyWith(phone: value));

  void setDocument(DocumentSlot slot, File file) {
    final updated = Map<DocumentSlot, IdentityDocumentModel>.from(
      state.documents,
    );
    updated[slot] = IdentityDocumentModel(slot: slot, file: file);
    emit(state.copyWith(documents: updated));
  }

  void removeDocument(DocumentSlot slot) {
    final updated = Map<DocumentSlot, IdentityDocumentModel>.from(
      state.documents,
    );
    updated.remove(slot);
    emit(state.copyWith(documents: updated));
  }

  /// [identity] et la pièce viennent du formulaire, préremplis par la lecture
  /// de la pièce et corrigés à la main : tous facultatifs.
  Future<void> submit({
    ClientIdDocumentType? documentType,
    String? documentNumber,
    ClientIdentity identity = ClientIdentity.empty,
  }) async {
    if (!state.isValid || state.isLoading) return;
    emit(state.copyWith(status: AddClientStatus.loading));

    try {
      final created = await _clients.create(
        fullName: state.fullName.trim(),
        phone: state.phone.trim(),
        idDocumentType: documentType,
        idDocumentNumber: documentNumber,
        identity: identity,
        documentFrontPath: state.documents[DocumentSlot.recto]?.file.path,
        documentBackPath: state.documents[DocumentSlot.verso]?.file.path,
      );
      if (isClosed) return;

      if (created.isOutOfScope) {
        emit(
          state.copyWith(
            status: AddClientStatus.error,
            errorMessage: clientOutOfScopeMessage,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: AddClientStatus.success,
          alreadyExisted: created.alreadyExisted,
        ),
      );
    } on AppFailure catch (f) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: AddClientStatus.error,
            errorMessage: f.userMessage,
          ),
        );
      }
    }
  }
}
