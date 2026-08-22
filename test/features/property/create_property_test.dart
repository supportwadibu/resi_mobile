import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';
import 'package:resi_africa/features/property/data/repositories/property_repository.dart';

/// Intercepte la requête composée, sans réseau.
class _CapturingInterceptor extends Interceptor {
  RequestOptions? captured;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured = options;
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 201,
        data: {
          'data': {
            'id': 'prop_1',
            'owner_id': 'own_1',
            'title': 'Villa Belvédère',
            'description': 'Une belle villa avec vue sur la lagune.',
            'property_type': 'villa',
            'status': 'draft',
            'address': {'street': 'Rue des Jardins', 'city': 'Abidjan'},
            'details': {
              'surface_area': 180,
              'bedrooms': 4,
              'bathrooms': 2,
              'living_rooms': 1,
              'kitchens': 1,
              'parking_spaces': 2,
            },
            'amenities': {'wifi': true, 'pool': true, 'gym': false},
            'media': {
              'images': ['https://cdn.test/a.jpg'],
            },
            'pricing': {'daily_price': 15000},
            'available_from': '2026-09-01T00:00:00.000Z',
            'visibility': {'is_public': false},
            'metadata': {'views_count': 0},
          },
        },
      ),
    );
  }
}

CreatePropertyPayload _payload({
  Set<Amenity> amenities = const {},
  List<String> images = const [],
  double? surfaceArea = 180,
  PropertyPricing pricing = const PropertyPricing(dailyPrice: 15000),
}) {
  return CreatePropertyPayload(
    title: 'Villa Belvédère',
    description: 'Une belle villa avec vue sur la lagune.',
    propertyType: PropertyType.villa,
    address: const PropertyAddress(
      street: 'Rue des Jardins',
      city: 'Abidjan',
      latitude: 5.35,
      longitude: -3.99,
    ),
    details: PropertyDetails(
      surfaceArea: surfaceArea,
      bedrooms: 4,
      bathrooms: 2,
      livingRooms: 1,
      kitchens: 1,
      parkingSpaces: 2,
      furnishing: Furnishing.furnished,
    ),
    amenities: amenities,
    images: images,
    pricing: pricing,
    availableFrom: DateTime(2026, 9, 1),
  );
}

void main() {
  late Dio dio;
  late _CapturingInterceptor interceptor;
  late PropertyRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    interceptor = _CapturingInterceptor();
    dio.interceptors.add(interceptor);
    repository = PropertyRepository(dio);
  });

  group('Contrat de création — champs exigés par l’API', () {
    test('la charge utile porte tous les champs requis', () async {
      await repository.create(_payload());
      final body = interceptor.captured!.data as Map<String, dynamic>;

      // Le validateur serveur refuse la requête si l'un manque.
      for (final key in [
        'title',
        'description',
        'property_type',
        'address',
        'details',
        'pricing',
        'available_from',
      ]) {
        expect(body.containsKey(key), isTrue, reason: '$key est requis');
      }
    });

    test('les détails portent les compteurs obligatoires', () async {
      await repository.create(_payload());
      final body = interceptor.captured!.data as Map<String, dynamic>;
      final details = body['details'] as Map<String, dynamic>;

      expect(details['surface_area'], 180);
      expect(details['bedrooms'], 4);
      expect(details['bathrooms'], 2);
      expect(details['living_rooms'], 1);
      expect(details['kitchens'], 1);
      expect(details['parking_spaces'], 2);
      expect(details['furnishing'], 'furnished');
    });

    test('la surface est omise quand elle n’est pas renseignée', () async {
      await repository.create(_payload(surfaceArea: null));
      final body = interceptor.captured!.data as Map<String, dynamic>;
      final details = body['details'] as Map<String, dynamic>;

      // `vine.number().positive().optional()` refuserait un `0` explicite :
      // la clé doit disparaître, pas valoir zéro.
      expect(details.containsKey('surface_area'), isFalse);
      // Le reste des caractéristiques part normalement.
      expect(details['bedrooms'], 4);
    });

    test('caution et durées de bail ne font plus partie du contrat', () async {
      await repository.create(_payload());
      final body = interceptor.captured!.data as Map<String, dynamic>;

      // Ces champs ont été retirés du système : le validateur serveur ne les
      // connaît plus, et les envoyer ferait échouer la requête.
      for (final key in [
        'deposit_amount',
        'minimum_lease_duration',
        'maximum_lease_duration',
        // Loyer mensuel de référence, remplacé par le seul tarif journalier.
        'rent_price',
      ]) {
        expect(body.containsKey(key), isFalse, reason: '$key a été retiré');
      }
    });

    test('le type part en code, jamais en libellé français', () async {
      await repository.create(_payload());
      final body = interceptor.captured!.data as Map<String, dynamic>;

      expect(body['property_type'], 'villa');
      expect(body['property_type'], isNot('Villa'));
    });

    test('available_from est une date simple', () async {
      await repository.create(_payload());
      final body = interceptor.captured!.data as Map<String, dynamic>;

      // `vine.date()` attend `YYYY-MM-DD`, pas un instant ISO complet.
      expect(body['available_from'], '2026-09-01');
    });

    test('les commodités partent en objet de booléens', () async {
      await repository.create(
        _payload(amenities: {Amenity.wifi, Amenity.pool}),
      );
      final body = interceptor.captured!.data as Map<String, dynamic>;
      final amenities = body['amenities'] as Map<String, dynamic>;

      expect(amenities['wifi'], isTrue);
      expect(amenities['pool'], isTrue);
      // Les non retenues sont absentes, jamais à `false` explicite.
      expect(amenities.containsKey('gym'), isFalse);
    });

    test('les coordonnées sont imbriquées comme l’attend l’API', () async {
      await repository.create(_payload());
      final body = interceptor.captured!.data as Map<String, dynamic>;
      final address = body['address'] as Map<String, dynamic>;
      final coordinates = address['coordinates'] as Map<String, dynamic>;

      expect(coordinates['latitude'], 5.35);
      expect(coordinates['longitude'], -3.99);
    });

    test('media est omis quand aucune photo n’a été déposée', () async {
      await repository.create(_payload());
      final body = interceptor.captured!.data as Map<String, dynamic>;

      expect(body.containsKey('media'), isFalse);
    });

    test('media porte les URLs quand il y en a', () async {
      await repository.create(
        _payload(images: const ['https://cdn.test/a.jpg']),
      );
      final body = interceptor.captured!.data as Map<String, dynamic>;
      final media = body['media'] as Map<String, dynamic>;

      expect(media['images'], ['https://cdn.test/a.jpg']);
    });

    test('les paliers de remise partent avec le tarif journalier', () async {
      await repository.create(
        _payload(
          pricing: const PropertyPricing(
            dailyPrice: 15000,
            priceTiers: [
              PriceTier(minDays: 7, discountPercent: 10),
              PriceTier(minDays: 30, discountPercent: 20),
            ],
          ),
        ),
      );
      final body = interceptor.captured!.data as Map<String, dynamic>;
      final pricing = body['pricing'] as Map<String, dynamic>;

      expect(pricing['daily_price'], 15000);
      expect(pricing['price_tiers'], [
        {'min_days': 7, 'discount_percent': 10},
        {'min_days': 30, 'discount_percent': 20},
      ]);
    });

    test('les anciens paliers hebdomadaire et mensuel ont disparu', () async {
      await repository.create(
        _payload(
          pricing: const PropertyPricing(
            dailyPrice: 15000,
            priceTiers: [PriceTier(minDays: 7, discountPercent: 10)],
          ),
        ),
      );
      final body = interceptor.captured!.data as Map<String, dynamic>;
      final pricing = body['pricing'] as Map<String, dynamic>;

      // Le validateur serveur ne les connaît plus.
      expect(pricing.containsKey('weekly_price'), isFalse);
      expect(pricing.containsKey('monthly_price'), isFalse);
    });

    test('sans remise, la clé `price_tiers` est omise', () async {
      await repository.create(_payload());
      final body = interceptor.captured!.data as Map<String, dynamic>;
      final pricing = body['pricing'] as Map<String, dynamic>;

      expect(pricing['daily_price'], 15000);
      // `vine.array().optional()` : une liste vide n'apporte rien, la clé
      // disparaît plutôt que de transporter `[]`.
      expect(pricing.containsKey('price_tiers'), isFalse);
    });

    test('cible la route propriétaire', () async {
      await repository.create(_payload());

      expect(interceptor.captured!.path, '/api/v1/proprio/properties');
    });
  });

  group('Lecture de la réponse', () {
    test('reconstruit le modèle depuis l’enveloppe `data`', () async {
      final property = await repository.create(_payload());

      expect(property.id, 'prop_1');
      expect(property.title, 'Villa Belvédère');
      expect(property.propertyType, PropertyType.villa);
      expect(property.status, PropertyStatus.draft);
      expect(property.address.city, 'Abidjan');
      expect(property.details.bedrooms, 4);
      expect(property.images, ['https://cdn.test/a.jpg']);
    });

    test('ne retient que les commodités à `true`', () async {
      final property = await repository.create(_payload());

      expect(property.amenities, contains(Amenity.wifi));
      expect(property.amenities, contains(Amenity.pool));
      // `gym` est à `false` : ce n'est pas une commodité présente.
      expect(property.amenities, isNot(contains(Amenity.gym)));
    });
  });

  group('Remise par durée', () {
    // Doit rester aligné sur `calculateStayPrice` et `resolveDiscountPercent`
    // dans `api_resi/app/features/bookings/stay_pricing.ts` : un écart
    // afficherait au locataire un montant que le serveur ne facturera pas.
    const pricing = PropertyPricing(
      dailyPrice: 15000,
      priceTiers: [
        PriceTier(minDays: 7, discountPercent: 10),
        PriceTier(minDays: 30, discountPercent: 20),
      ],
    );

    test('en deçà du premier palier, le tarif plein s’applique', () {
      expect(pricing.discountPercentFor(1), 0);
      expect(pricing.discountPercentFor(6), 0);
      expect(pricing.subtotalFor(3), 45000);
    });

    test('le palier s’applique dès sa durée exacte', () {
      expect(pricing.discountPercentFor(7), 10);
      expect(pricing.subtotalFor(7), 94500);
    });

    test('un séjour intermédiaire garde le palier atteint', () {
      expect(pricing.discountPercentFor(10), 10);
      // 10 × 15 000 = 150 000, remisé de 10 %.
      expect(pricing.subtotalFor(10), 135000);
    });

    test('le palier le plus avantageux gagne', () {
      expect(pricing.discountPercentFor(45), 20);
      expect(pricing.subtotalFor(30), 360000);
    });

    test('sans palier, la durée ne change rien au prix unitaire', () {
      const flat = PropertyPricing(dailyPrice: 15000);

      expect(flat.discountPercentFor(90), 0);
      expect(flat.subtotalFor(90), 1350000);
    });

    test('les paliers désordonnés sont remis en ordre à la lecture', () {
      final parsed = PropertyPricing.fromJson(const {
        'daily_price': 15000,
        'price_tiers': [
          {'min_days': 30, 'discount_percent': 20},
          {'min_days': 7, 'discount_percent': 10},
        ],
      });

      expect(parsed.priceTiers.map((t) => t.minDays), [7, 30]);
      expect(parsed.discountPercentFor(30), 20);
    });

    test('le sous-total est arrondi au franc', () {
      const odd = PropertyPricing(
        dailyPrice: 10000,
        priceTiers: [PriceTier(minDays: 3, discountPercent: 33)],
      );

      // 3 × 10 000 × 0,67 = 20 100 exactement ; aucune décimale ne doit
      // subsister sur un montant en FCFA.
      expect(odd.subtotalFor(3), 20100);
      expect(odd.subtotalFor(3) % 1, 0);
    });
  });

  group('Dépôt des photos', () {
    test('un lot vide n’appelle pas le serveur', () async {
      final urls = await repository.uploadImages(const []);

      expect(urls, isEmpty);
      expect(interceptor.captured, isNull);
    });
  });

  group('Correspondance des énumérations avec le serveur', () {
    test('les types couvrent exactement PROPERTY_TYPES', () {
      // Doit rester aligné sur `app/validators/property/property.ts`.
      expect(PropertyType.values.map((t) => t.code).toSet(), {
        'apartment',
        'studio',
        'villa',
        'duplex',
      });
    });

    test('les commodités couvrent exactement amenitiesSchema', () {
      expect(Amenity.values.map((a) => a.code).toSet(), {
        'air_conditioning',
        'heating',
        'elevator',
        'balcony',
        'terrace',
        'garden',
        'pool',
        'gym',
        'security',
        'concierge',
        'wifi',
        'parking',
        'pet_friendly',
        'smoking_allowed',
      });
    });

    test('l’ameublement couvre exactement FURNISHING', () {
      expect(Furnishing.values.map((f) => f.code).toSet(), {
        'unfurnished',
        'semi_furnished',
        'furnished',
      });
    });
  });
}
