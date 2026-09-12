/// Lieu regroupant plusieurs logements loués séparément — « Resi Adja » et ses
/// trois unités.
///
/// Distincte d'un bien : une résidence **ne se loue pas**. Elle porte
/// l'adresse, les parties communes et les charges communes ; ce sont ses unités
/// (des `PropertyModel`) qui portent le tarif, le calendrier et les
/// réservations.
///
/// Ne pas confondre avec `ResidenceOption` du formulaire de dépense, qui
/// sélectionne historiquement un *bien* malgré son nom.
library;

/// Équipement d'une partie commune, aligné sur le serveur.
///
/// Plus court que les commodités d'un bien : seuls les équipements du lieu
/// figurent ici, la climatisation ou le balcon variant d'une unité à l'autre.
enum ResidenceAmenity {
  pool('pool', 'Piscine'),
  gym('gym', 'Salle de sport'),
  security('security', 'Gardiennage'),
  concierge('concierge', 'Conciergerie'),
  elevator('elevator', 'Ascenseur'),
  parking('parking', 'Parking'),
  garden('garden', 'Jardin'),
  wifi('wifi', 'Wi-Fi');

  const ResidenceAmenity(this.code, this.label);

  final String code;
  final String label;

  static ResidenceAmenity? fromCode(String? code) {
    for (final value in ResidenceAmenity.values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

class ResidenceAddress {
  const ResidenceAddress({
    required this.street,
    required this.city,
    this.country = 'CI',
    this.postalCode,
  });

  final String street;
  final String city;
  final String country;
  final String? postalCode;

  factory ResidenceAddress.fromJson(Map<String, dynamic> json) {
    return ResidenceAddress(
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? 'CI',
      postalCode: json['postal_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'street': street,
    'city': city,
    'country': country,
    if (postalCode != null && postalCode!.trim().isNotEmpty)
      'postal_code': postalCode!.trim(),
  };
}

class ResidenceModel {
  const ResidenceModel({
    required this.id,
    required this.name,
    required this.address,
    this.description = '',
    this.amenities = const {},
    this.images = const [],
    this.unitsCount = 0,
  });

  final String id;
  final String name;
  final String description;
  final ResidenceAddress address;
  final Set<ResidenceAmenity> amenities;
  final List<String> images;

  /// Nombre d'unités rattachées, dénormalisé côté serveur.
  ///
  /// Sert à l'affichage (« 3 logements ») et à prévenir que la suppression
  /// sera refusée tant qu'il n'est pas à zéro.
  final int unitsCount;

  /// Une résidence sans unité n'est pas encore louable.
  bool get isEmpty => unitsCount == 0;

  factory ResidenceModel.fromJson(Map<String, dynamic> json) {
    final amenities = json['amenities'] as Map<String, dynamic>? ?? const {};
    final media = json['media'] as Map<String, dynamic>? ?? const {};

    return ResidenceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      address: ResidenceAddress.fromJson(
        json['address'] as Map<String, dynamic>? ?? const {},
      ),
      // Seules les clés à `true` désignent un équipement présent, comme pour
      // les commodités d'un bien.
      amenities: {
        for (final entry in amenities.entries)
          if (entry.value == true) ?ResidenceAmenity.fromCode(entry.key),
      },
      images:
          (media['images'] as List<dynamic>?)?.cast<String>().toList() ??
          const [],
      unitsCount: (json['units_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResidenceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Charge utile de création, distincte du modèle de lecture.
class CreateResidencePayload {
  const CreateResidencePayload({
    required this.name,
    required this.address,
    this.description,
    this.amenities = const {},
  });

  final String name;
  final ResidenceAddress address;
  final String? description;
  final Set<ResidenceAmenity> amenities;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'address': address.toJson(),
    if (description != null && description!.trim().isNotEmpty)
      'description': description!.trim(),
    // Seuls les équipements cochés partent : le serveur complète les absents à
    // `false`, et les envoyer tous alourdirait la requête sans rien ajouter.
    if (amenities.isNotEmpty)
      'amenities': {for (final a in amenities) a.code: true},
  };
}

/// Charge utile de modification.
///
/// Seules les clés fournies partent : l'API applique un patch partiel par
/// chemins pointés, et envoyer un champ inchangé risquerait d'écraser une
/// valeur modifiée ailleurs.
class UpdateResidencePayload {
  const UpdateResidencePayload({
    this.name,
    this.description,
    this.address,
    this.amenities,
  });

  final String? name;
  final String? description;
  final ResidenceAddress? address;

  /// `null` signifie « ne pas toucher ». Un ensemble vide efface tous les
  /// équipements, ce qui est une intention distincte.
  final Set<ResidenceAmenity>? amenities;

  Map<String, dynamic> toJson() => {
    if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
    if (description != null) 'description': description!.trim(),
    if (address != null) 'address': address!.toJson(),
    if (amenities != null)
      'amenities': {
        for (final a in ResidenceAmenity.values) a.code: amenities!.contains(a),
      },
  };

  bool get isEmpty => toJson().isEmpty;
}

/// Une page de résidences, avec son bloc `meta`.
class ResidencePage {
  const ResidencePage({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  final List<ResidenceModel> items;
  final int total;
  final int currentPage;
  final int lastPage;

  bool get hasMore => currentPage < lastPage;

  factory ResidencePage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? const [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return ResidencePage(
      items: [
        for (final item in data)
          ResidenceModel.fromJson(item as Map<String, dynamic>),
      ],
      total: (meta['total'] as num?)?.toInt() ?? data.length,
      currentPage: (meta['currentPage'] as num?)?.toInt() ?? 1,
      lastPage: (meta['lastPage'] as num?)?.toInt() ?? 1,
    );
  }
}
