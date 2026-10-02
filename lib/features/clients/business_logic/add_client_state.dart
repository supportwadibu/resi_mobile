import '../data/models/identity_document_model.dart';

enum AddClientStatus { idle, loading, success, error }

/// Coordonnées et photos de la pièce.
///
/// La nature, le numéro et l'identité de la pièce n'y figurent pas : ils vivent
/// dans le `ClientIdentityController` de l'écran, que la lecture de la pièce
/// préremplit, et sont remis au cubit à l'envoi.
class AddClientState {
  final String fullName;
  final String phone;
  final Map<DocumentSlot, IdentityDocumentModel> documents;

  final AddClientStatus status;
  final String? errorMessage;

  /// Le numéro était déjà au carnet : le serveur a rendu la fiche existante au
  /// lieu d'en créer un doublon.
  final bool alreadyExisted;

  /// Fiche saisie hors ligne, créée au serveur au retour du réseau.
  final bool queued;

  const AddClientState({
    this.fullName = '',
    this.phone = '',
    this.documents = const {},
    this.status = AddClientStatus.idle,
    this.errorMessage,
    this.alreadyExisted = false,
    this.queued = false,
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
    AddClientStatus? status,
    String? errorMessage,
    bool? alreadyExisted,
    bool? queued,
  }) {
    return AddClientState(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      documents: documents ?? this.documents,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      alreadyExisted: alreadyExisted ?? this.alreadyExisted,
      queued: queued ?? this.queued,
    );
  }
}
