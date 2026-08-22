import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/identity_document_model.dart';
import 'add_client_state.dart';

class AddClientCubit extends Cubit<AddClientState> {
  AddClientCubit() : super(const AddClientState());

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

  Future<void> submit() async {
    if (!state.isValid) return;
    emit(state.copyWith(status: AddClientStatus.loading));
    try {
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: AddClientStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: AddClientStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
