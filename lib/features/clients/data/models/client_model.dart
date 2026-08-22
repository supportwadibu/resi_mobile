/// Statut d'une fiche du carnet, aligné sur `CLIENT_STATUSES` du serveur.
enum ClientStatus {
  active('active', 'Actif'),
  archived('archived', 'Archivé');

  const ClientStatus(this.code, this.label);

  final String code;
  final String label;

  static ClientStatus fromCode(String? code) {
    for (final status in ClientStatus.values) {
      if (status.code == code) return status;
    }
    // Un statut inconnu vaut mieux affiché comme actif que faire échouer la
    // lecture de tout le carnet.
    return ClientStatus.active;
  }
}

/// Type de pièce d'identité, aligné sur `ID_DOCUMENT_TYPES` du serveur.
enum ClientIdDocumentType {
  cni('cni', 'CNI'),
  passeport('passeport', 'Passeport'),
  permis('permis', 'Permis de conduire');

  const ClientIdDocumentType(this.code, this.label);

  final String code;
  final String label;

  static ClientIdDocumentType? fromCode(String? code) {
    if (code == null) return null;
    for (final type in ClientIdDocumentType.values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

/// Cumul des séjours d'un client, alimenté par le serveur à chaque clôture.
class ClientStats {
  const ClientStats({
    this.totalStays = 0,
    this.totalPaid = 0,
    this.lastStayAt,
  });

  final int totalStays;
  final double totalPaid;
  final DateTime? lastStayAt;

  factory ClientStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ClientStats();
    return ClientStats(
      totalStays: (json['total_stays'] as num?)?.toInt() ?? 0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0,
      lastStayAt: _parseDate(json['last_stay_at']),
    );
  }
}

/// Client du carnet, tel que servi par `GET /proprio/clients`.
///
/// Les pièces d'identité ne circulent jamais sous forme de référence
/// d'hébergement : le serveur n'expose que leur présence, et des URLs signées
/// à durée limitée sur la lecture d'une fiche.
class ClientModel {
  const ClientModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.whatsapp,
    this.idDocumentType,
    this.idDocumentNumber,
    this.hasDocumentFront = false,
    this.hasDocumentBack = false,
    this.documentsComplete = false,
    this.stats = const ClientStats(),
    this.status = ClientStatus.active,
    this.documentFrontUrl,
    this.documentBackUrl,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? whatsapp;

  final ClientIdDocumentType? idDocumentType;
  final String? idDocumentNumber;

  final bool hasDocumentFront;
  final bool hasDocumentBack;

  /// Dossier complet : les deux faces de la pièce sont déposées.
  ///
  /// Les pièces étant facultatives à l'enregistrement — au comptoir, un client
  /// peut ne pas avoir sa pièce sur lui — ce drapeau sert à relancer.
  final bool documentsComplete;

  final ClientStats stats;
  final ClientStatus status;

  /// URLs signées, présentes seulement sur la lecture d'une fiche et valables
  /// quelques minutes. Ne jamais les persister : elles expirent.
  final String? documentFrontUrl;
  final String? documentBackUrl;

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      whatsapp: json['whatsapp'] as String?,
      idDocumentType: ClientIdDocumentType.fromCode(
        json['id_document_type'] as String?,
      ),
      idDocumentNumber: json['id_document_number'] as String?,
      hasDocumentFront: json['has_document_front'] as bool? ?? false,
      hasDocumentBack: json['has_document_back'] as bool? ?? false,
      documentsComplete: json['documents_status'] == 'complete',
      stats: ClientStats.fromJson(json['stats'] as Map<String, dynamic>?),
      status: ClientStatus.fromCode(json['status'] as String?),
      documentFrontUrl: json['document_front_url'] as String?,
      documentBackUrl: json['document_back_url'] as String?,
    );
  }

  /// Initiales affichées à défaut de photo, au plus deux lettres.
  String get avatarInitials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return _initial(parts.first);
    return '${_initial(parts.first)}${_initial(parts.last)}';
  }

  static String _initial(String word) =>
      word.isEmpty ? '' : word.substring(0, 1).toUpperCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ClientModel(id: $id, phone: $phone)';
}

/// Les dates arrivent en ISO 8601 ; une valeur illisible vaut `null` plutôt
/// qu'une exception au milieu du décodage d'une liste.
DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
