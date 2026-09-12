import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/residence/data/models/residence_model.dart';
import 'package:resi_africa/features/residence/data/repositories/residence_repository.dart';

/// Intercepte la requête composée, sans réseau.
class _CapturingInterceptor extends Interceptor {
  _CapturingInterceptor(this.body);

  final Object? Function(RequestOptions options) body;

  final List<RequestOptions> captured = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured.add(options);
    handler.resolve(
      Response(requestOptions: options, statusCode: 200, data: body(options)),
    );
  }
}

const _residenceJson = {
  'id': 'resi-adja',
  'owner_id': 'own_1',
  'name': 'Resi Adja',
  'description': 'Trois logements à Cocody',
  'address': {
    'street': 'Rue des Jardins',
    'city': 'Abidjan',
    'country': 'CI',
    'postal_code': '01 BP 1234',
  },
  'amenities': {'pool': true, 'security': true, 'gym': false},
  'media': {'images': <String>['https://img/1.jpg']},
  'units_count': 3,
};

({ResidenceRepository repo, _CapturingInterceptor spy}) _build(
  Object? Function(RequestOptions options) body,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  final spy = _CapturingInterceptor(body);
  dio.interceptors.add(spy);
  return (repo: ResidenceRepository(dio), spy: spy);
}

void main() {
  group('ResidenceModel', () {
    test('lit une résidence complète', () {
      final residence = ResidenceModel.fromJson(_residenceJson);

      expect(residence.id, 'resi-adja');
      expect(residence.name, 'Resi Adja');
      expect(residence.address.city, 'Abidjan');
      expect(residence.unitsCount, 3);
      expect(residence.isEmpty, isFalse);
      expect(residence.images, hasLength(1));
    });

    test('ne retient que les équipements à true', () {
      final residence = ResidenceModel.fromJson(_residenceJson);

      expect(residence.amenities, contains(ResidenceAmenity.pool));
      expect(residence.amenities, contains(ResidenceAmenity.security));
      // `gym: false` ne désigne pas un équipement présent.
      expect(residence.amenities, isNot(contains(ResidenceAmenity.gym)));
    });

    test('une résidence sans unité est signalée vide', () {
      // Sert à prévenir le propriétaire qu'elle n'est pas encore louable.
      final residence = ResidenceModel.fromJson({
        'id': 'r2',
        'name': 'Nouvelle',
        'units_count': 0,
      });

      expect(residence.isEmpty, isTrue);
    });

    test('tolère une réponse minimale', () {
      // Compatibilité ascendante : une résidence écrite avant l'ajout du
      // compteur n'en porte pas.
      final residence = ResidenceModel.fromJson({'id': 'r3', 'name': 'Minimale'});

      expect(residence.unitsCount, 0);
      expect(residence.address.city, '');
      expect(residence.amenities, isEmpty);
      expect(residence.images, isEmpty);
    });
  });

  group('CreateResidencePayload', () {
    test('n’envoie que les équipements cochés', () {
      final json = CreateResidencePayload(
        name: '  Resi Adja  ',
        address: const ResidenceAddress(street: 'Rue A', city: 'Abidjan'),
        amenities: {ResidenceAmenity.pool},
      ).toJson();

      // Le nom est débarrassé de ses espaces, le serveur le faisant aussi.
      expect(json['name'], 'Resi Adja');
      expect(json['amenities'], {'pool': true});
    });

    test('omet les équipements quand aucun n’est coché', () {
      final json = CreateResidencePayload(
        name: 'Resi',
        address: const ResidenceAddress(street: 'Rue A', city: 'Abidjan'),
      ).toJson();

      expect(json.containsKey('amenities'), isFalse);
    });
  });

  group('UpdateResidencePayload', () {
    test('un patch vide ne part pas', () {
      expect(const UpdateResidencePayload().isEmpty, isTrue);
    });

    test('un ensemble vide efface tous les équipements', () {
      // Distinct de `null`, qui signifie « ne pas toucher » : le serveur reçoit
      // alors chaque clé à `false`.
      final json = const UpdateResidencePayload(amenities: {}).toJson();

      expect(json['amenities'], isA<Map<String, bool>>());
      expect((json['amenities'] as Map).values, everyElement(isFalse));
    });
  });

  group('ResidenceRepository', () {
    test('getAllResidences parcourt les pages en série', () async {
      // Deux pages : le sélecteur doit proposer l'ensemble, pas la première.
      final built = _build((options) {
        final page = int.parse(options.queryParameters['page'].toString());
        return {
          'data': [
            {..._residenceJson, 'id': 'r$page'},
          ],
          'meta': {'total': 2, 'currentPage': page, 'lastPage': 2},
        };
      });

      final all = await built.repo.getAllResidences();

      expect(all.map((r) => r.id), ['r1', 'r2']);
      expect(built.spy.captured, hasLength(2));
    });

    test('attachToResidence envoie le rattachement et le libellé', () async {
      final built = _build(
        (_) => {
          'data': {
            'id': 'studio-1',
            'title': 'Studio 1',
            'residence_id': 'resi-adja',
            'unit_label': 'Studio 1',
          },
        },
      );

      await built.repo.attachToResidence(
        'studio-1',
        residenceId: 'resi-adja',
        unitLabel: 'Studio 1',
      );

      final sent = built.spy.captured.single;
      expect(sent.path, contains('/properties/studio-1/residence'));
      expect(sent.method, 'PATCH');
      expect((sent.data as Map)['residence_id'], 'resi-adja');
      expect((sent.data as Map)['unit_label'], 'Studio 1');
      // L'adresse n'est recopiée que sur demande : un bien publié porte une
      // adresse que ses annonces affichent.
      expect((sent.data as Map).containsKey('copy_address'), isFalse);
    });

    test('le détachement envoie un residence_id nul', () async {
      final built = _build((_) => {'data': {'id': 'studio-1', 'title': 'Studio 1'}});

      await built.repo.attachToResidence('studio-1', residenceId: null);

      final sent = built.spy.captured.single;
      // La clé doit partir avec `null`, et non être omise : c'est ce `null` qui
      // détache le bien côté serveur.
      expect((sent.data as Map).containsKey('residence_id'), isTrue);
      expect((sent.data as Map)['residence_id'], isNull);
    });

    test('copyAddress est transmis quand il est demandé', () async {
      final built = _build((_) => {'data': {'id': 'studio-1', 'title': 'Studio 1'}});

      await built.repo.attachToResidence(
        'studio-1',
        residenceId: 'resi-adja',
        copyAddress: true,
      );

      expect((built.spy.captured.single.data as Map)['copy_address'], isTrue);
    });
  });
}
