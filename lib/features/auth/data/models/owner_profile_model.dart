/// Types de pièces d'identité acceptés par l'API.
///
/// Les codes doivent rester alignés sur `ID_DOCUMENT_TYPES` côté serveur : le
/// libellé affiché est décidé ici, le code transmis ne l'est pas.
enum IdDocumentType {
  cni('cni', 'Carte nationale d’identité', requiresBack: true),
  passport('passport', 'Passeport', requiresBack: false),
  drivingLicence('driving_licence', 'Permis de conduire', requiresBack: true);

  const IdDocumentType(this.code, this.label, {required this.requiresBack});

  /// Valeur transmise à l'API.
  final String code;

  /// Libellé montré à l'utilisateur.
  final String label;

  /// Le verso porte-t-il une information à fournir ?
  ///
  /// Un passeport s'identifie par sa seule page de données : en exiger le
  /// verso bloquerait des dossiers valides.
  final bool requiresBack;

  static IdDocumentType? fromCode(String? code) {
    if (code == null) return null;
    for (final type in IdDocumentType.values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

/// Dossier de validation du propriétaire, tel que renvoyé par
/// `GET /api/v1/proprio/profile`.
///
/// Les deux URLs de justificatifs sont **signées et temporaires** : elles
/// servent à l'affichage immédiat et ne doivent pas être mises en cache ni
/// persistées, sous peine de liens morts à la prochaine ouverture.
class OwnerProfileModel {
  const OwnerProfileModel({
    required this.fullName,
    required this.isSubmitted,
    this.email,
    this.phone,
    this.avatarUrl,
    this.address,
    this.city,
    this.country,
    this.idDocumentType,
    this.idDocumentNumber,
    this.idDocumentFrontUrl,
    this.idDocumentBackUrl,
    this.submittedAt,
    this.ownerStatus,
    this.rejectionReason,
  });

  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  final String? address;
  final String? city;
  final String? country;

  final IdDocumentType? idDocumentType;
  final String? idDocumentNumber;
  final String? idDocumentFrontUrl;
  final String? idDocumentBackUrl;

  /// Date de dépôt du dossier, `null` tant que rien n'a été transmis.
  final DateTime? submittedAt;

  /// Le dossier a-t-il été déposé ?
  final bool isSubmitted;

  /// `pending`, `active`, `rejected` ou `suspended`.
  final String? ownerStatus;

  /// Motif du refus, renseigné uniquement lorsque le dossier a été rejeté.
  final String? rejectionReason;

  /// Le dossier a été examiné puis refusé : l'utilisateur doit le corriger.
  bool get isRejected => ownerStatus == 'rejected';

  /// Le dossier a été validé par un administrateur.
  bool get isValidated => ownerStatus == 'active';

  /// L'essai s'est achevé sans validation du dossier.
  ///
  /// La suspension est fonctionnelle, jamais authentifiante : le compte reste
  /// accessible pour permettre la régularisation.
  bool get isSuspended => ownerStatus == 'suspended';

  /// Le dossier est déposé mais n'a pas encore été examiné.
  bool get isUnderReview => isSubmitted && ownerStatus == 'pending';

  /// Libellé du statut, tel que présenté à l'utilisateur.
  String get statusLabel => switch (ownerStatus) {
    'active' => 'Dossier validé',
    'rejected' => 'Dossier refusé',
    'suspended' => 'Compte suspendu',
    _ when isSubmitted => 'En cours de vérification',
    _ => 'Dossier à compléter',
  };

  factory OwnerProfileModel.fromJson(Map<String, dynamic> json) {
    final submittedAt = json['submitted_at'] as String?;

    return OwnerProfileModel(
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      idDocumentType: IdDocumentType.fromCode(
        json['id_document_type'] as String?,
      ),
      idDocumentNumber: json['id_document_number'] as String?,
      idDocumentFrontUrl: json['id_document_front_url'] as String?,
      idDocumentBackUrl: json['id_document_back_url'] as String?,
      submittedAt: submittedAt == null ? null : DateTime.tryParse(submittedAt),
      isSubmitted: json['is_submitted'] as bool? ?? false,
      ownerStatus: json['owner_status'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}
