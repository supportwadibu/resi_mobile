import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/session_role_fixture.dart';
import 'package:resi_africa/core/error/failures.dart';
import 'package:resi_africa/features/property/business_logic/edit_property_cubit.dart';
import 'package:resi_africa/features/property/business_logic/edit_property_state.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';
import 'package:resi_africa/features/property/data/repositories/property_repository.dart';

/// Fiche renvoyée par l'API, quel que soit l'appel.
Map<String, dynamic> _propertyJson({
  bool isPublic = false,
  String status = 'draft',
}) => {
  'id': 'prop_1',
  'owner_id': 'own_1',
  'title': 'Villa Belvédère',
  'description': 'Une belle villa avec vue sur la lagune.',
  'property_type': 'villa',
  'status': status,
  'address': {'street': 'Rue des Jardins', 'city': 'Abidjan'},
  'details': {
    'surface_area': 180,
    'bedrooms': 4,
    'bathrooms': 2,
    'living_rooms': 1,
    'kitchens': 1,
    'parking_spaces': 2,
  },
  'amenities': {'wifi': true},
  'media': {
    'images': ['https://cdn.test/a.jpg'],
  },
  'pricing': {'daily_price': 15000},
  'available_from': '2026-09-01T00:00:00.000Z',
  'visibility': {'is_public': isPublic},
  'metadata': {'views_count': 0},
};

/// Intercepte les requêtes et répond sans réseau.
class _CapturingInterceptor extends Interceptor {
  final List<RequestOptions> requests = [];

  /// Réponse imposée au prochain appel, pour simuler un refus serveur.
  DioException? failWith;

  /// URLs renvoyées par le dépôt de photos, dans l'ordre.
  List<String> uploadResult = const ['https://cdn.test/new.jpg'];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);

    final failure = failWith;
    if (failure != null) {
      failWith = null;
      handler.reject(failure.copyWith(requestOptions: options));
      return;
    }

    if (options.path.endsWith('/images')) {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 201,
          data: {
            'data': {'images': uploadResult},
          },
        ),
      );
      return;
    }

    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'data': _propertyJson(
            isPublic: options.path.endsWith('/publish'),
            status: options.path.endsWith('/publish') ? 'published' : 'draft',
          ),
        },
      ),
    );
  }
}

PropertyModel _original({
  List<String> images = const ['https://cdn.test/a.jpg'],
}) {
  return PropertyModel(
    id: 'prop_1',
    ownerId: 'own_1',
    title: 'Villa Belvédère',
    description: 'Une belle villa avec vue sur la lagune.',
    propertyType: PropertyType.villa,
    status: PropertyStatus.draft,
    address: const PropertyAddress(street: 'Rue des Jardins', city: 'Abidjan'),
    details: const PropertyDetails(
      surfaceArea: 180,
      bedrooms: 4,
      bathrooms: 2,
      livingRooms: 1,
      kitchens: 1,
      parkingSpaces: 2,
    ),
    amenities: const {Amenity.wifi},
    images: images,
    pricing: const PropertyPricing(dailyPrice: 15000),
    availableFrom: DateTime.utc(2026, 9, 1),
  );
}

/// Soumet la fiche au cubit, en ne changeant que ce qui est passé.
Future<void> _submit(
  EditPropertyCubit cubit,
  PropertyModel original, {
  String? title,
  List<String>? images,
}) {
  return cubit.submit(
    original: original,
    title: title ?? original.title,
    description: original.description,
    propertyType: original.propertyType,
    address: original.address,
    details: original.details,
    amenities: original.amenities,
    images: images ?? original.images,
    pricing: original.pricing,
  );
}

void main() {
  late Dio dio;
  late _CapturingInterceptor interceptor;
  late PropertyRepository repository;
  late Directory tempDir;

  /// Chemin d'une photo réellement présente sur le disque.
  ///
  /// `MultipartFile.fromFile` ouvre le fichier : un chemin inventé ferait
  /// échouer le dépôt avant même la requête, et le test ne prouverait rien du
  /// tri entre photos locales et URLs.
  late String localPhoto;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    interceptor = _CapturingInterceptor();
    dio.interceptors.add(interceptor);
    repository = PropertyRepository(dio, sessionRoleFixture());

    tempDir = Directory.systemTemp.createTempSync('resi_edit_test');
    localPhoto = '${tempDir.path}${Platform.pathSeparator}photo.jpg';
    File(localPhoto).writeAsBytesSync(const [0xFF, 0xD8, 0xFF]);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  group('PropertyRepository — modification', () {
    test('la modification part en PATCH sur la fiche visée', () async {
      await repository.update(
        'prop_1',
        UpdatePropertyPayload.diff(
          original: _original(),
          title: 'Nouveau titre',
          description: _original().description,
          propertyType: PropertyType.villa,
          address: _original().address,
          details: _original().details,
          amenities: _original().amenities,
          images: _original().images,
          pricing: _original().pricing,
        ),
      );

      final request = interceptor.requests.single;
      expect(request.method, 'PATCH');
      expect(request.path, '/api/v1/proprio/properties/prop_1');
      expect(request.data, {'title': 'Nouveau titre'});
    });

    test('publier et retirer visent leurs routes dédiées', () async {
      await repository.publish('prop_1');
      await repository.unpublish('prop_1');

      expect(interceptor.requests.map((r) => r.path), [
        '/api/v1/proprio/properties/prop_1/publish',
        '/api/v1/proprio/properties/prop_1/unpublish',
      ]);
      expect(interceptor.requests.every((r) => r.method == 'PATCH'), isTrue);
    });

    test('la fiche publiée revient avec sa visibilité à jour', () async {
      final published = await repository.publish('prop_1');
      expect(published.isPublic, isTrue);
      expect(published.status, PropertyStatus.published);
    });

    test('un refus 403 conserve le message du serveur', () async {
      interceptor.failWith = DioException(
        requestOptions: RequestOptions(path: '/publish'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/publish'),
          statusCode: 403,
          data: {
            'code': 'owner_profile_required',
            'message':
                'Complétez votre dossier (pièce d’identité et coordonnées) avant de publier une annonce.',
          },
        ),
      );

      // Le propriétaire doit lire ce qu'il lui reste à faire, pas « Accès
      // refusé » qui ne dit rien de la marche à suivre.
      await expectLater(
        repository.publish('prop_1'),
        throwsA(
          isA<AppFailure>()
              .having((f) => f.statusCode, 'statusCode', 403)
              .having(
                (f) => f.userMessage,
                'userMessage',
                contains('Complétez votre dossier'),
              ),
        ),
      );
    });
  });

  group('EditPropertyCubit', () {
    test('une fiche inchangée n’appelle pas l’API', () async {
      final cubit = EditPropertyCubit(repository);
      final original = _original();

      await _submit(cubit, original);

      expect(interceptor.requests, isEmpty);
      expect(
        cubit.state,
        isA<EditPropertySuccess>().having(
          (s) => s.unchanged,
          'unchanged',
          true,
        ),
      );
    });

    test('un champ modifié déclenche un PATCH', () async {
      final cubit = EditPropertyCubit(repository);

      await _submit(cubit, _original(), title: 'Villa rénovée');

      expect(interceptor.requests.single.method, 'PATCH');
      expect(
        cubit.state,
        isA<EditPropertySuccess>().having(
          (s) => s.unchanged,
          'unchanged',
          false,
        ),
      );
    });

    test('seules les photos locales sont déposées', () async {
      final cubit = EditPropertyCubit(repository);
      interceptor.uploadResult = const ['https://cdn.test/new.jpg'];

      await _submit(
        cubit,
        _original(),
        images: ['https://cdn.test/a.jpg', localPhoto],
      );

      // Deux appels : le dépôt de l'unique fichier local, puis le PATCH.
      expect(interceptor.requests.length, 2);
      expect(interceptor.requests.first.path, endsWith('/images'));

      final body = interceptor.requests.last.data as Map<String, dynamic>;
      // L'URL déjà hébergée est conservée telle quelle, à sa place.
      expect(body['media'], {
        'images': ['https://cdn.test/a.jpg', 'https://cdn.test/new.jpg'],
      });
    });

    test('l’ordre choisi est préservé, couverture comprise', () async {
      final cubit = EditPropertyCubit(repository);
      interceptor.uploadResult = const ['https://cdn.test/new.jpg'];

      // La photo locale est placée en tête : elle devient la couverture.
      await _submit(
        cubit,
        _original(),
        images: [localPhoto, 'https://cdn.test/a.jpg'],
      );

      final body = interceptor.requests.last.data as Map<String, dynamic>;
      expect(body['media'], {
        'images': ['https://cdn.test/new.jpg', 'https://cdn.test/a.jpg'],
      });
    });

    test('aucune photo locale n’appelle le dépôt', () async {
      final cubit = EditPropertyCubit(repository);

      await _submit(cubit, _original(), title: 'Villa rénovée');

      expect(
        interceptor.requests.any((r) => r.path.endsWith('/images')),
        isFalse,
      );
    });

    test(
      'un échec d’enregistrement conserve les photos déjà déposées',
      () async {
        final cubit = EditPropertyCubit(repository);
        final original = _original();
        interceptor.uploadResult = const ['https://cdn.test/new.jpg'];

        // Le dépôt passe, le PATCH échoue : les fichiers sont hébergés, et les
        // renvoyer au prochain essai gaspillerait le forfait du propriétaire.
        var seen = 0;
        dio.interceptors.insert(
          0,
          InterceptorsWrapper(
            onRequest: (options, handler) {
              if (options.path.endsWith('prop_1') && seen++ == 0) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.connectionError,
                  ),
                );
                return;
              }
              handler.next(options);
            },
          ),
        );

        await _submit(
          cubit,
          original,
          images: ['https://cdn.test/a.jpg', localPhoto],
        );

        expect(cubit.state, isA<EditPropertyFailure>());
        expect((cubit.state as EditPropertyFailure).uploadedImages, [
          'https://cdn.test/new.jpg',
        ]);

        // Nouvelle tentative : le fichier local n'est pas redéposé.
        final before = interceptor.requests
            .where((r) => r.path.endsWith('/images'))
            .length;

        await _submit(
          cubit,
          original,
          images: ['https://cdn.test/a.jpg', localPhoto],
        );

        final after = interceptor.requests
            .where((r) => r.path.endsWith('/images'))
            .length;
        expect(after, before);
        expect(cubit.state, isA<EditPropertySuccess>());
      },
    );

    test('un échec imprévu rend la main au lieu de figer l’écran', () async {
      final cubit = EditPropertyCubit(
        _ThrowingRepository(dio, sessionRoleFixture()),
      );
      addTearDown(cubit.close);

      await _submit(cubit, _original(), title: 'Nouveau titre');

      // L'écran enveloppe le formulaire dans un `AbsorbPointer` piloté par
      // l'état : rester sur `Submitting` n'y laisserait plus passer aucun
      // geste, et le propriétaire ne pourrait que tuer l'application.
      expect(cubit.state, isA<EditPropertyFailure>());
    });
  });
}

/// Repository qui échoue hors du contrat [AppFailure].
///
/// Rejoue ce qu'aucune couche ne garantit : une `TypeError` sur une réponse
/// inattendue, un bogue de sérialisation. Le cubit doit retomber sur un état
/// d'échec, jamais rester en cours.
class _ThrowingRepository extends PropertyRepository {
  _ThrowingRepository(super.dio, super.role);

  @override
  Future<PropertyModel> update(String id, UpdatePropertyPayload payload) async {
    throw StateError('panne imprévue');
  }
}
