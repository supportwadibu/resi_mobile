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

/// Bornes admises pour une valeur de palier. [max] nul : pas de plafond.
class TierBounds {
  const TierBounds({required this.min, this.max});

  final int min;
  final int? max;

  /// Ramène [value] dans les bornes plutôt que de la refuser : l'écran cale
  /// ainsi la saisie sur la limite au lieu d'ignorer le geste sans rien dire.
  int clamp(int value) {
    final floored = value < min ? min : value;
    final ceiling = max;
    return ceiling != null && floored > ceiling ? ceiling : floored;
  }

  bool get allowsIncrement => max == null || max! > min;
}

/// Règles de cohérence d'une liste de paliers de remise.
///
/// L'API ne valide chaque palier qu'isolément (`min_days ≥ 2`,
/// `discount_percent ∈ [1, 90]`) : rien ne l'empêche d'enregistrer deux
/// paliers de même durée, ou une remise qui décroît quand le séjour s'allonge.
/// Un tel palier est accepté mais ne s'applique jamais — [PropertyPricing]
/// retient la remise la plus avantageuse atteinte, pas la dernière déclarée.
/// Ces règles rendent l'état incohérent inatteignable depuis le formulaire.
abstract final class PriceTierList {
  /// Durée minimale d'un palier, imposée par le validateur serveur.
  static const int minDaysFloor = 2;

  static const int minDiscount = 1;
  static const int maxDiscount = 90;

  /// Liste triée par durée croissante.
  ///
  /// Les annonces enregistrées avant cette normalisation peuvent porter leurs
  /// paliers dans n'importe quel ordre : l'écran les présente ordonnés.
  static List<PriceTier> sorted(List<PriceTier> tiers) =>
      [...tiers]..sort((a, b) => a.minDays.compareTo(b.minDays));

  /// Durées admises pour le palier [index], au vu de ses voisins.
  static TierBounds minDaysBounds(List<PriceTier> tiers, int index) {
    final previous = index > 0 ? tiers[index - 1].minDays : null;
    final next = index < tiers.length - 1 ? tiers[index + 1].minDays : null;

    return TierBounds(
      min: previous == null ? minDaysFloor : previous + 1,
      max: next == null ? null : next - 1,
    );
  }

  /// Remises admises pour le palier [index].
  ///
  /// La remise croît avec la durée : un séjour plus long ne peut pas être
  /// moins avantageux qu'un séjour plus court.
  static TierBounds discountBounds(List<PriceTier> tiers, int index) {
    final previous = index > 0 ? tiers[index - 1].discountPercent : null;
    final next = index < tiers.length - 1
        ? tiers[index + 1].discountPercent
        : null;

    return TierBounds(
      min: previous == null ? minDiscount : previous + 1,
      max: next == null ? maxDiscount : next - 1,
    );
  }

  /// Remplace le palier [index], en ramenant ses valeurs dans les bornes.
  static List<PriceTier> replace(
    List<PriceTier> tiers,
    int index,
    PriceTier tier,
  ) {
    final updated = [...tiers];
    updated[index] = PriceTier(
      minDays: minDaysBounds(tiers, index).clamp(tier.minDays),
      discountPercent: discountBounds(tiers, index).clamp(tier.discountPercent),
    );
    return updated;
  }

  static List<PriceTier> removed(List<PriceTier> tiers, int index) =>
      [...tiers]..removeAt(index);

  /// Reste-t-il de la place pour un palier supplémentaire ?
  ///
  /// Non quand le dernier atteint déjà la remise maximale : le suivant devrait
  /// être plus avantageux, et aucune valeur ne le permet.
  static bool canAppend(List<PriceTier> tiers) =>
      tiers.isEmpty || tiers.last.discountPercent < maxDiscount;

  /// Ajoute un palier plus long et plus avantageux que le dernier.
  static List<PriceTier> appended(List<PriceTier> tiers) {
    if (!canAppend(tiers)) return tiers;
    if (tiers.isEmpty) {
      // La semaine : premier seuil que les propriétaires proposent
      // spontanément, et point de bascule courant d'un séjour de passage.
      return const [PriceTier(minDays: 7, discountPercent: 10)];
    }

    final last = tiers.last;
    final nextDays = switch (last.minDays) {
      < 7 => 7,
      < 30 => 30,
      _ => last.minDays + 30,
    };

    return [
      ...tiers,
      PriceTier(
        minDays: nextDays,
        // +5 points, sans dépasser le plafond ni rejoindre le palier
        // précédent — la borne basse reste `last + 1`.
        discountPercent: (last.discountPercent + 5).clamp(
          last.discountPercent + 1,
          maxDiscount,
        ),
      ),
    ];
  }

  /// Le palier [index] est-il sans effet ?
  ///
  /// Ne survient que sur des données historiques : un palier plus long dont la
  /// remise n'excède pas celle d'un palier plus court ne sera jamais retenu.
  static bool isIneffective(List<PriceTier> tiers, int index) {
    final tier = tiers[index];
    for (var i = 0; i < tiers.length; i++) {
      if (i == index) continue;
      final other = tiers[i];
      if (other.minDays <= tier.minDays &&
          other.discountPercent >= tier.discountPercent) {
        return true;
      }
    }
    return false;
  }
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
    this.residenceId,
    this.unitLabel,
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

  /// Résidence du logement, `null` pour un bien autonome.
  ///
  /// Absent des biens créés avant l'introduction des résidences : `null`
  /// signifie « autonome », le comportement d'origine.
  final String? residenceId;

  /// Nom du logement dans sa résidence — « Studio 1 ».
  ///
  /// Distinct de [title], qui reste le titre de l’annonce vu par le client.
  final String? unitLabel;

  /// Le logement appartient-il à une résidence ?
  bool get belongsToResidence => residenceId != null;

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
      residenceId: json['residence_id'] as String?,
      unitLabel: json['unit_label'] as String?,
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

/// Charge utile de modification : uniquement ce que le propriétaire a changé.
///
/// `PATCH` est partiel côté API, et c'est ici une garantie, pas une commodité :
/// `media.images` et `pricing.price_tiers` sont **remplacés** par ce qu'on
/// envoie. Retransmettre l'intégralité de la fiche à chaque enregistrement
/// ferait réécrire des tableaux que l'utilisateur n'a pas touchés.
///
/// Trois champs sont volontairement absents du corps produit :
/// - `visibility` — la mise en ligne passe par `publish`/`unpublish`, qui
///   vérifient le dossier d'identité et horodatent la publication ;
/// - `residence_id` — le rattachement a sa propre route, qui déplace les
///   compteurs des deux résidences ;
/// - `status` — il se déduit des réservations, le poser à la main
///   réintroduirait un état bloqué que rien ne remet à zéro.
class UpdatePropertyPayload {
  const UpdatePropertyPayload._(this._fields);

  final Map<String, dynamic> _fields;

  /// Compare la saisie à [original] et ne retient que les écarts.
  factory UpdatePropertyPayload.diff({
    required PropertyModel original,
    required String title,
    required String description,
    required PropertyType propertyType,
    required PropertyAddress address,
    required PropertyDetails details,
    required Set<Amenity> amenities,
    required List<String> images,
    required PropertyPricing pricing,
    bool? chargesIncluded,
    double? additionalCharges,
    DateTime? availableFrom,
  }) {
    final fields = <String, dynamic>{};

    if (title != original.title) fields['title'] = title;
    if (description != original.description) {
      fields['description'] = description;
    }
    if (propertyType != original.propertyType) {
      fields['property_type'] = propertyType.code;
    }

    // Les objets imbriqués se comparent sur leur forme sérialisée : le modèle
    // n'implémente pas `==`, et l'écart qui compte est celui que verra l'API.
    final addressJson = address.toJson();
    if (!_sameJson(addressJson, original.address.toJson())) {
      fields['address'] = addressJson;
    }

    final detailsJson = details.toJson();
    if (!_sameJson(detailsJson, original.details.toJson())) {
      // Une surface effacée doit être transmise à `null` : la clé omise par
      // `PropertyDetails.toJson` laisserait l'ancienne valeur en place.
      fields['details'] = {'surface_area': null, ...detailsJson};
    }

    if (!_sameAmenities(amenities, original.amenities)) {
      // L'objet complet, y compris les `false` : n'envoyer que les commodités
      // retenues rendrait tout retrait invisible côté serveur.
      fields['amenities'] = {
        for (final amenity in Amenity.values)
          amenity.code: amenities.contains(amenity),
      };
    }

    // L'ordre compte : la première photo sert de couverture.
    if (!_sameList(images, original.images)) {
      fields['media'] = {'images': images};
    }

    final pricingJson = pricing.toJson();
    if (!_sameJson(pricingJson, original.pricing.toJson())) {
      // Même raison que pour la surface : sans clé explicite, vider les
      // paliers de remise ne les supprimerait pas.
      fields['pricing'] = {'price_tiers': const <dynamic>[], ...pricingJson};
    }

    if (chargesIncluded != null &&
        chargesIncluded != original.chargesIncluded) {
      fields['charges_included'] = chargesIncluded;
    }
    if (additionalCharges != null &&
        additionalCharges != original.additionalCharges) {
      fields['additional_charges'] = additionalCharges;
    }
    if (availableFrom != null &&
        !_sameDay(availableFrom, original.availableFrom)) {
      fields['available_from'] = CreatePropertyPayload._formatDate(
        availableFrom,
      );
    }

    return UpdatePropertyPayload._(fields);
  }

  /// Aucun écart : il n'y a rien à envoyer, et l'appel peut être épargné.
  bool get isEmpty => _fields.isEmpty;

  Map<String, dynamic> toJson() => Map.unmodifiable(_fields);

  /// Égalité structurelle sur des cartes issues de `toJson`.
  ///
  /// `DeepCollectionEquality` viendrait de `collection`, que le projet n'a pas
  /// en dépendance directe : la comparaison manuelle évite d'en ajouter une
  /// pour ce seul usage.
  static bool _sameJson(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (!_sameValue(entry.value, b[entry.key])) return false;
    }
    return true;
  }

  static bool _sameValue(dynamic a, dynamic b) {
    if (a is Map<String, dynamic> && b is Map<String, dynamic>) {
      return _sameJson(a, b);
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_sameValue(a[i], b[i])) return false;
      }
      return true;
    }
    // `15000` et `15000.0` désignent le même tarif : un modèle relu depuis
    // l'API porte des `int` là où la saisie produit des `double`.
    if (a is num && b is num) return a.toDouble() == b.toDouble();
    return a == b;
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// L'ordre d'un `Set` ne porte pas de sens : seule la composition compte.
  static bool _sameAmenities(Set<Amenity> a, Set<Amenity> b) =>
      a.length == b.length && a.containsAll(b);

  /// `available_from` est une date, pas un instant : comparer les `DateTime`
  /// bruts signalerait un écart à chaque ouverture du formulaire.
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
