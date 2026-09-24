import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';

/// Bien de référence, dans l'état où l'API l'a renvoyé.
PropertyModel _original({
  String title = 'Villa Belvédère',
  Set<Amenity> amenities = const {Amenity.wifi, Amenity.pool},
  List<String> images = const ['https://cdn.test/a.jpg'],
  PropertyPricing pricing = const PropertyPricing(dailyPrice: 15000),
  PropertyAddress? address,
  PropertyDetails? details,
}) {
  return PropertyModel(
    id: 'prop_1',
    ownerId: 'own_1',
    title: title,
    description: 'Une belle villa avec vue sur la lagune.',
    propertyType: PropertyType.villa,
    status: PropertyStatus.published,
    address:
        address ??
        const PropertyAddress(
          street: 'Rue des Jardins',
          city: 'Abidjan',
          latitude: 5.35,
          longitude: -3.99,
        ),
    details:
        details ??
        const PropertyDetails(
          surfaceArea: 180,
          bedrooms: 4,
          bathrooms: 2,
          livingRooms: 1,
          kitchens: 1,
          parkingSpaces: 2,
        ),
    amenities: amenities,
    images: images,
    pricing: pricing,
    availableFrom: DateTime.utc(2026, 9, 1),
  );
}

void main() {
  group('UpdatePropertyPayload — diff', () {
    test('un bien inchangé ne produit aucun champ', () {
      final property = _original();

      final payload = UpdatePropertyPayload.diff(
        original: property,
        title: property.title,
        description: property.description,
        propertyType: property.propertyType,
        address: property.address,
        details: property.details,
        amenities: property.amenities,
        images: property.images,
        pricing: property.pricing,
      );

      expect(payload.isEmpty, isTrue);
      expect(payload.toJson(), isEmpty);
    });

    test('seul le champ modifié est transmis', () {
      final property = _original();

      final payload = UpdatePropertyPayload.diff(
        original: property,
        title: 'Villa Belvédère rénovée',
        description: property.description,
        propertyType: property.propertyType,
        address: property.address,
        details: property.details,
        amenities: property.amenities,
        images: property.images,
        pricing: property.pricing,
      );

      expect(payload.isEmpty, isFalse);
      expect(payload.toJson(), {'title': 'Villa Belvédère rénovée'});
    });

    test('les commodités se comparent sans tenir compte de l’ordre', () {
      final property = _original(amenities: {Amenity.wifi, Amenity.pool});

      final payload = UpdatePropertyPayload.diff(
        original: property,
        title: property.title,
        description: property.description,
        propertyType: property.propertyType,
        address: property.address,
        details: property.details,
        // Même ensemble, énuméré dans l'autre sens.
        amenities: {Amenity.pool, Amenity.wifi},
        images: property.images,
        pricing: property.pricing,
      );

      expect(payload.toJson(), isEmpty);
    });

    test('une commodité retirée renvoie l’objet complet des booléens', () {
      final property = _original(amenities: {Amenity.wifi, Amenity.pool});

      final payload = UpdatePropertyPayload.diff(
        original: property,
        title: property.title,
        description: property.description,
        propertyType: property.propertyType,
        address: property.address,
        details: property.details,
        amenities: {Amenity.wifi},
        images: property.images,
        pricing: property.pricing,
      );

      // Le retrait ne se voit que si la clé est envoyée à `false` : un objet
      // ne portant que les commodités retenues laisserait la piscine en place.
      expect(payload.toJson()['amenities'], {
        for (final amenity in Amenity.values)
          amenity.code: amenity == Amenity.wifi,
      });
    });

    test('des photos inchangées ne réécrivent pas media', () {
      final property = _original(images: const ['a.jpg', 'b.jpg']);

      final payload = UpdatePropertyPayload.diff(
        original: property,
        title: property.title,
        description: property.description,
        propertyType: property.propertyType,
        address: property.address,
        details: property.details,
        amenities: property.amenities,
        images: const ['a.jpg', 'b.jpg'],
        pricing: property.pricing,
      );

      expect(payload.toJson().containsKey('media'), isFalse);
    });

    test('un ordre de photos modifié est transmis', () {
      final property = _original(images: const ['a.jpg', 'b.jpg']);

      final payload = UpdatePropertyPayload.diff(
        original: property,
        title: property.title,
        description: property.description,
        propertyType: property.propertyType,
        address: property.address,
        details: property.details,
        amenities: property.amenities,
        // La première photo sert de couverture : l'ordre porte du sens.
        images: const ['b.jpg', 'a.jpg'],
        pricing: property.pricing,
      );

      expect(payload.toJson()['media'], {
        'images': ['b.jpg', 'a.jpg'],
      });
    });

    test('retirer toutes les photos transmet une liste vide', () {
      final property = _original(images: const ['a.jpg']);

      final payload = UpdatePropertyPayload.diff(
        original: property,
        title: property.title,
        description: property.description,
        propertyType: property.propertyType,
        address: property.address,
        details: property.details,
        amenities: property.amenities,
        images: const [],
        pricing: property.pricing,
      );

      // `if (images.isNotEmpty)` conviendrait à la création, jamais ici : la
      // clé absente laisserait les photos en place côté serveur.
      expect(payload.toJson()['media'], {'images': <String>[]});
    });

    test('un palier de remise modifié transmet la tarification entière', () {
      final property = _original(
        pricing: const PropertyPricing(
          dailyPrice: 15000,
          priceTiers: [PriceTier(minDays: 7, discountPercent: 10)],
        ),
      );

      final payload = UpdatePropertyPayload.diff(
        original: property,
        title: property.title,
        description: property.description,
        propertyType: property.propertyType,
        address: property.address,
        details: property.details,
        amenities: property.amenities,
        images: property.images,
        pricing: const PropertyPricing(
          dailyPrice: 15000,
          priceTiers: [PriceTier(minDays: 7, discountPercent: 15)],
        ),
      );

      expect(payload.toJson()['pricing'], {
        'daily_price': 15000.0,
        'price_tiers': [
          {'min_days': 7, 'discount_percent': 15},
        ],
      });
    });

    test('vider les paliers transmet une liste vide', () {
      final property = _original(
        pricing: const PropertyPricing(
          dailyPrice: 15000,
          priceTiers: [PriceTier(minDays: 7, discountPercent: 10)],
        ),
      );

      final payload = UpdatePropertyPayload.diff(
        original: property,
        title: property.title,
        description: property.description,
        propertyType: property.propertyType,
        address: property.address,
        details: property.details,
        amenities: property.amenities,
        images: property.images,
        pricing: const PropertyPricing(dailyPrice: 15000),
      );

      // Même raison que pour les photos : la clé omise garderait les paliers.
      expect((payload.toJson()['pricing'] as Map)['price_tiers'], isEmpty);
    });

    test('une surface effacée est transmise à null', () {
      final property = _original();

      final payload = UpdatePropertyPayload.diff(
        original: property,
        title: property.title,
        description: property.description,
        propertyType: property.propertyType,
        address: property.address,
        details: const PropertyDetails(
          surfaceArea: null,
          bedrooms: 4,
          bathrooms: 2,
          livingRooms: 1,
          kitchens: 1,
          parkingSpaces: 2,
        ),
        amenities: property.amenities,
        images: property.images,
        pricing: property.pricing,
      );

      expect((payload.toJson()['details'] as Map)['surface_area'], isNull);
    });

    test('les coordonnées relevées sont transmises avec l’adresse', () {
      final property = _original();

      final payload = UpdatePropertyPayload.diff(
        original: property,
        title: property.title,
        description: property.description,
        propertyType: property.propertyType,
        address: const PropertyAddress(
          street: 'Rue des Jardins',
          city: 'Abidjan',
          latitude: 5.36,
          longitude: -3.99,
        ),
        details: property.details,
        amenities: property.amenities,
        images: property.images,
        pricing: property.pricing,
      );

      expect(payload.toJson()['address'], {
        'street': 'Rue des Jardins',
        'city': 'Abidjan',
        'coordinates': {'latitude': 5.36, 'longitude': -3.99},
      });
    });

    test('ni visibility ni status ni residence_id ne sont jamais émis', () {
      final property = _original();

      final payload = UpdatePropertyPayload.diff(
        original: property,
        title: 'Autre titre',
        description: 'Une autre description, suffisamment longue.',
        propertyType: PropertyType.duplex,
        address: const PropertyAddress(street: 'Ailleurs', city: 'Bouaké'),
        details: const PropertyDetails(
          bedrooms: 1,
          bathrooms: 1,
          livingRooms: 1,
          kitchens: 1,
          parkingSpaces: 0,
        ),
        amenities: const {},
        images: const [],
        pricing: const PropertyPricing(dailyPrice: 9000),
      );

      // L'API refuse ces champs sur PATCH :id — la publication et le
      // rattachement à une résidence ont leurs propres routes.
      final json = payload.toJson();
      expect(json.containsKey('visibility'), isFalse);
      expect(json.containsKey('status'), isFalse);
      expect(json.containsKey('residence_id'), isFalse);
    });
  });
}
