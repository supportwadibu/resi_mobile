/// Type de bien, tel que l'API le nomme.
///
/// Le code est ce qui transite (`apartment`), le libellé ce qui s'affiche
/// (« Appartement ») : les confondre enverrait du français à un validateur qui
/// n'accepte que les valeurs de l'énumération.
enum PropertyType {
  apartment('apartment', 'Appartement'),
  studio('studio', 'Studio'),
  villa('villa', 'Villa'),
  duplex('duplex', 'Duplex');

  const PropertyType(this.code, this.label);

  final String code;
  final String label;

  static PropertyType? fromCode(String? code) {
    if (code == null) return null;
    for (final type in PropertyType.values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

/// Niveau d'ameublement.
enum Furnishing {
  unfurnished('unfurnished', 'Non meublé'),
  semiFurnished('semi_furnished', 'Semi-meublé'),
  furnished('furnished', 'Meublé');

  const Furnishing(this.code, this.label);

  final String code;
  final String label;

  static Furnishing? fromCode(String? code) {
    if (code == null) return null;
    for (final value in Furnishing.values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Statut d'une annonce côté serveur.
enum PropertyStatus {
  draft('draft', 'Brouillon'),
  published('published', 'Publiée'),
  reserved('reserved', 'Réservée'),
  rented('rented', 'Louée'),
  maintenance('maintenance', 'En travaux'),
  inactive('inactive', 'Inactive');

  const PropertyStatus(this.code, this.label);

  final String code;
  final String label;

  static PropertyStatus? fromCode(String? code) {
    if (code == null) return null;
    for (final value in PropertyStatus.values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Adresse du bien. `street` et `city` sont exigés par l'API.
class PropertyAddress {
  const PropertyAddress({
    required this.street,
    required this.city,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  final String street;
  final String city;
  final String? country;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  factory PropertyAddress.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'] as Map<String, dynamic>?;
    return PropertyAddress(
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String?,
      postalCode: json['postal_code'] as String?,
      latitude: (coordinates?['latitude'] as num?)?.toDouble(),
      longitude: (coordinates?['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'street': street,
    'city': city,
    if (country != null && country!.isNotEmpty) 'country': country,
    if (postalCode != null && postalCode!.isNotEmpty) 'postal_code': postalCode,
    if (latitude != null || longitude != null)
      'coordinates': {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
  };
}

/// Caractéristiques du bien. Les six premiers champs sont exigés par l'API.
class PropertyDetails {
  const PropertyDetails({
    this.surfaceArea,
    required this.bedrooms,
    required this.bathrooms,
    required this.livingRooms,
    required this.kitchens,
    required this.parkingSpaces,
    this.floorNumber,
    this.totalFloors,
    this.yearBuilt,
    this.furnishing,
  });

  /// Surface habitable en m². Optionnelle : tous les propriétaires ne la
  /// connaissent pas, et l'exiger bloquait le dépôt d'une annonce par ailleurs
  /// complète.
  final double? surfaceArea;
  final int bedrooms;
  final int bathrooms;
  final int livingRooms;
  final int kitchens;
  final int parkingSpaces;
  final int? floorNumber;
  final int? totalFloors;
  final int? yearBuilt;
  final Furnishing? furnishing;

  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    return PropertyDetails(
      surfaceArea: (json['surface_area'] as num?)?.toDouble(),
      bedrooms: (json['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (json['bathrooms'] as num?)?.toInt() ?? 0,
      livingRooms: (json['living_rooms'] as num?)?.toInt() ?? 0,
      kitchens: (json['kitchens'] as num?)?.toInt() ?? 0,
      parkingSpaces: (json['parking_spaces'] as num?)?.toInt() ?? 0,
      floorNumber: (json['floor_number'] as num?)?.toInt(),
      totalFloors: (json['total_floors'] as num?)?.toInt(),
      yearBuilt: (json['year_built'] as num?)?.toInt(),
      furnishing: Furnishing.fromCode(json['furnishing'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    // Omise plutôt qu'envoyée à zéro : le validateur exige une valeur
    // strictement positive dès que la clé est présente.
    if (surfaceArea != null) 'surface_area': surfaceArea,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'living_rooms': livingRooms,
    'kitchens': kitchens,
    'parking_spaces': parkingSpaces,
    if (floorNumber != null) 'floor_number': floorNumber,
    if (totalFloors != null) 'total_floors': totalFloors,
    if (yearBuilt != null) 'year_built': yearBuilt,
    if (furnishing != null) 'furnishing': furnishing!.code,
  };
}

/// Commodités, telles que l'API les nomme.
///
/// Le serveur attend un objet de booléens à clés fixes, jamais une liste
/// libre : les commodités affichées côté mobile doivent donc se rattacher à
/// l'une de ces clés, ou n'être pas transmises.
enum Amenity {
  airConditioning('air_conditioning', 'Climatisation'),
  heating('heating', 'Chauffe-eau'),
  elevator('elevator', 'Ascenseur'),
  balcony('balcony', 'Balcon'),
  terrace('terrace', 'Terrasse'),
  garden('garden', 'Jardin'),
  pool('pool', 'Piscine'),
  gym('gym', 'Salle de sport'),
  security('security', 'Sécurité 24h'),
  concierge('concierge', 'Concierge'),
  wifi('wifi', 'Wifi'),
  parking('parking', 'Parking'),
  petFriendly('pet_friendly', 'Animaux acceptés'),
  smokingAllowed('smoking_allowed', 'Fumeurs acceptés');

  const Amenity(this.code, this.label);

  final String code;
  final String label;

  static Amenity? fromCode(String? code) {
    if (code == null) return null;
    for (final value in Amenity.values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Remise accordée à partir d'une certaine durée de séjour.
///
/// Le prix par jour reste l'unique référence : un palier applique un
/// pourcentage de remise sur tout le séjour dès que celui-ci atteint [minDays].
class PriceTier {
  const PriceTier({required this.minDays, required this.discountPercent});

  /// Durée à partir de laquelle la remise s'applique, en jours.
  final int minDays;

  /// Pourcentage de remise, de 1 à 90 — la borne haute exigée par l'API.
  final int discountPercent;

  factory PriceTier.fromJson(Map<String, dynamic> json) => PriceTier(
    minDays: (json['min_days'] as num?)?.toInt() ?? 0,
    discountPercent: (json['discount_percent'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'min_days': minDays,
    'discount_percent': discountPercent,
  };

  PriceTier copyWith({int? minDays, int? discountPercent}) => PriceTier(
    minDays: minDays ?? this.minDays,
    discountPercent: discountPercent ?? this.discountPercent,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceTier &&
          minDays == other.minDays &&
          discountPercent == other.discountPercent;

  @override
  int get hashCode => Object.hash(minDays, discountPercent);
}

/// Tarification. `dailyPrice` est exigé par l'API.
///
/// Une journée court de l'heure d'arrivée à la même heure le lendemain : entrer
/// à 12h et sortir le lendemain à 12h compte pour un jour.
class PropertyPricing {
  const PropertyPricing({
    required this.dailyPrice,
    this.priceTiers = const [],
    this.minimumStayDays,
    this.maximumStayDays,
  });

  final double dailyPrice;

  /// Paliers de remise par durée, triés par durée croissante.
  ///
  /// Le propriétaire les modifie à tout moment ; une réservation déjà passée
  /// conserve le tarif figé au moment de sa création.
  final List<PriceTier> priceTiers;

  final int? minimumStayDays;
  final int? maximumStayDays;

  factory PropertyPricing.fromJson(Map<String, dynamic> json) {
    // `toList()` sans argument produit une liste modifiable : le tri qui suit
    // opère en place, et le repli doit l'être aussi.
    final tiers =
        (json['price_tiers'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(PriceTier.fromJson)
            .toList() ??
        <PriceTier>[];

    // L'API renvoie déjà des paliers ordonnés, mais un document écrit avant
    // cette normalisation doit rester lisible : le calcul local dépend de
    // l'ordre.
    tiers.sort((a, b) => a.minDays.compareTo(b.minDays));

    return PropertyPricing(
      dailyPrice: (json['daily_price'] as num?)?.toDouble() ?? 0,
      priceTiers: tiers,
      minimumStayDays: (json['minimum_stay_days'] as num?)?.toInt(),
      maximumStayDays: (json['maximum_stay_days'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'daily_price': dailyPrice,
    if (priceTiers.isNotEmpty)
      'price_tiers': [for (final tier in priceTiers) tier.toJson()],
    if (minimumStayDays != null) 'minimum_stay_days': minimumStayDays,
    if (maximumStayDays != null) 'maximum_stay_days': maximumStayDays,
  };

  /// Remise applicable à [days] : le palier le plus avantageux atteint.
  int discountPercentFor(int days) {
    var best = 0;
    for (final tier in priceTiers) {
      if (days >= tier.minDays && tier.discountPercent > best) {
        best = tier.discountPercent;
      }
    }
    return best;
  }

  /// Montant d'un séjour de [days] jours, remise de durée appliquée.
  ///
  /// Reproduit le calcul de l'API pour afficher un montant avant envoi ; le
  /// serveur reste seul à faire foi sur le montant encaissé.
  double subtotalFor(int days) {
    final full = days * dailyPrice;
    // Arrondi au franc, comme côté serveur : le FCFA n'a pas de subdivision.
    return (full * (1 - discountPercentFor(days) / 100)).roundToDouble();
  }
}

/// Annonce, telle que renvoyée par `GET/POST /proprio/properties`.
class PropertyModel {
  const PropertyModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.propertyType,
    required this.status,
    required this.address,
    required this.details,
    required this.amenities,
    required this.images,
    required this.pricing,
    required this.availableFrom,
    this.chargesIncluded = false,
    this.additionalCharges = 0,
    this.isPublic = false,
    this.viewsCount = 0,
  });

  final String id;
  final String ownerId;
  final String title;
  final String description;
  final PropertyType propertyType;
  final PropertyStatus status;
  final PropertyAddress address;
  final PropertyDetails details;
  final Set<Amenity> amenities;
  final List<String> images;
  final PropertyPricing pricing;
  final DateTime availableFrom;
  final bool chargesIncluded;
  final double additionalCharges;
  final bool isPublic;
  final int viewsCount;

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final amenities = json['amenities'] as Map<String, dynamic>? ?? const {};
    final media = json['media'] as Map<String, dynamic>? ?? const {};
    final visibility = json['visibility'] as Map<String, dynamic>? ?? const {};
    final metadata = json['metadata'] as Map<String, dynamic>? ?? const {};

    return PropertyModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      propertyType:
          PropertyType.fromCode(json['property_type'] as String?) ??
          PropertyType.apartment,
      status:
          PropertyStatus.fromCode(json['status'] as String?) ??
          PropertyStatus.draft,
      address: PropertyAddress.fromJson(
        json['address'] as Map<String, dynamic>? ?? const {},
      ),
      details: PropertyDetails.fromJson(
        json['details'] as Map<String, dynamic>? ?? const {},
      ),
      // Seules les clés à `true` désignent une commodité présente.
      amenities: {
        for (final entry in amenities.entries)
          if (entry.value == true) ?Amenity.fromCode(entry.key),
      },
      images:
          (media['images'] as List<dynamic>?)?.cast<String>().toList() ??
          const [],
      pricing: PropertyPricing.fromJson(
        json['pricing'] as Map<String, dynamic>? ?? const {},
      ),
      availableFrom:
          DateTime.tryParse(json['available_from'] as String? ?? '') ??
          DateTime.now(),
      chargesIncluded: json['charges_included'] as bool? ?? false,
      additionalCharges: (json['additional_charges'] as num?)?.toDouble() ?? 0,
      isPublic: visibility['is_public'] as bool? ?? false,
      viewsCount: (metadata['views_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PropertyModel(id: $id, title: $title)';
}

/// Charge utile de création, distincte du modèle de lecture.
///
/// Une annonce lue porte des champs que le serveur seul décide (`id`,
/// `status`, compteurs) : les inclure ici laisserait croire qu'on peut les
/// imposer.
class CreatePropertyPayload {
  const CreatePropertyPayload({
    required this.title,
    required this.description,
    required this.propertyType,
    required this.address,
    required this.details,
    required this.amenities,
    required this.images,
    required this.pricing,
    required this.availableFrom,
    this.chargesIncluded = false,
    this.additionalCharges,
  });

  final String title;
  final String description;
  final PropertyType propertyType;
  final PropertyAddress address;
  final PropertyDetails details;
  final Set<Amenity> amenities;
  final List<String> images;
  final PropertyPricing pricing;
  final DateTime availableFrom;
  final bool chargesIncluded;
  final double? additionalCharges;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'property_type': propertyType.code,
    'address': address.toJson(),
    'details': details.toJson(),
    // L'API attend un objet de booléens : seules les commodités retenues sont
    // transmises, les absentes valant `false` par défaut côté serveur.
    'amenities': {for (final amenity in amenities) amenity.code: true},
    if (images.isNotEmpty) 'media': {'images': images},
    'pricing': pricing.toJson(),
    'charges_included': chargesIncluded,
    if (additionalCharges != null) 'additional_charges': additionalCharges,
    // `vine.date()` attend une date, pas un instant ISO complet.
    'available_from': _formatDate(availableFrom),
  };

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
