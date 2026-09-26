import '../data/models/client_model.dart';
import '../data/models/identity_document_model.dart';

enum AddClientStatus { idle, loading, success, error }

class AddClientState {
  final String fullName;
  final String phone;
  final Map<DocumentSlot, IdentityDocumentModel> documents;

  /// Pièce lue par l'OCR. Non lus, ces champs se complètent depuis la fiche.
  final ClientIdDocumentType? idDocumentType;
  final String? idDocumentNumber;

  final AddClientStatus status;
  final String? errorMessage;

  /// Le numéro était déjà au carnet : le serveur a rendu la fiche existante au
  /// lieu d'en créer un doublon.
  final bool alreadyExisted;

  const AddClientState({
    this.fullName = '',
    this.phone = '',
    this.documents = const {},
    this.idDocumentType,
    this.idDocumentNumber,
    this.status = AddClientStatus.idle,
    this.errorMessage,
    this.alreadyExisted = false,
  });

  /// Nom et téléphone suffisent : les pièces sont facultatives, comme au
  /// comptoir. Les exiger bloquait l'enregistrement d'un client venu sans sa
  /// pièce.
  bool get isValid => fullName.trim().length >= 2 && phone.trim().length >= 8;

  bool get isLoading => status == AddClientStatus.loading;

  AddClientState copyWith({
    String? fullName,
    String? phone,
    Map<DocumentSlot, IdentityDocumentModel>? documents,
    ClientIdDocumentType? idDocumentType,
    String? idDocumentNumber,
    AddClientStatus? status,
    String? errorMessage,
    bool? alreadyExisted,
  }) {
    return AddClientState(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      documents: documents ?? this.documents,
      idDocumentType: idDocumentType ?? this.idDocumentType,
      idDocumentNumber: idDocumentNumber ?? this.idDocumentNumber,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      alreadyExisted: alreadyExisted ?? this.alreadyExisted,
    );
  }
}
