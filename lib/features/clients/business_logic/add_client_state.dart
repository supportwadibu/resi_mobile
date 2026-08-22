import '../data/models/identity_document_model.dart';

enum AddClientStatus { idle, loading, success, error }

class AddClientState {
  final String fullName;
  final String phone;
  final Map<DocumentSlot, IdentityDocumentModel> documents;
  final AddClientStatus status;
  final String? errorMessage;

  const AddClientState({
    this.fullName = '',
    this.phone = '',
    this.documents = const {},
    this.status = AddClientStatus.idle,
    this.errorMessage,
  });

  bool get isValid =>
      fullName.trim().length >= 2 &&
      phone.trim().length >= 8 &&
      documents.length == DocumentSlot.values.length;

  bool get isLoading => status == AddClientStatus.loading;

  AddClientState copyWith({
    String? fullName,
    String? phone,
    Map<DocumentSlot, IdentityDocumentModel>? documents,
    AddClientStatus? status,
    String? errorMessage,
  }) {
    return AddClientState(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      documents: documents ?? this.documents,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
