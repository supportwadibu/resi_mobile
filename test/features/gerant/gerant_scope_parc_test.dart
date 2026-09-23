import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/features/property/data/repositories/property_repository.dart';

import '../../support/session_role_fixture.dart';

/// Faux serveur paginé, sans réseau.
///
/// Rend la tranche demandée d'un parc, et le `meta` qui va avec — c'est
/// exactement ce que le client doit savoir lire pour ne rien laisser au-delà
/// de la première page.
class _PagedInterceptor extends Interceptor {
  _PagedInterceptor(this.total, {this.lastPageOverride});

  final int total;

  /// Sert à simuler un serveur qui annonce indéfiniment une page suivante :
  /// le client ne doit pas s'y perdre.
  final int? lastPageOverride;

  /// Chaque requête servie, dans l'ordre — les assertions y lisent `per_page`
  /// et le nombre d'appels réellement passés.
  final List<RequestOptions> requests = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);

    final page = (options.queryParameters['page'] as int?) ?? 1;
    final perPage = (options.queryParameters['per_page'] as int?) ?? 20;

    final start = (page - 1) * perPage;
    final end = (start + perPage).clamp(0, total);
    final items = [
      for (var i = start; i < end; i++) _propertyJson('p-${i + 1}'),
    ];

    final lastPage =
        lastPageOverride ??
        (total == 0 ? 1 : ((total + perPage - 1) ~/ perPage));

    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'data': items,
          'meta': {
            'total': total,
            'perPage': perPage,
            'currentPage': page,
            'lastPage': lastPage,
          },
        },
      ),
    );
  }
}

/// Fiche minimale : seul l'identifiant porte le sens ici, le reste du modèle
/// se remplit par ses propres replis.
Map<String, dynamic> _propertyJson(String id) => {
  'id': id,
  'title': 'Logement $id',
  'residence_id': 'res-1',
};

void main() {
  late _PagedInterceptor interceptor;
  late PropertyRepository repository;

  void arrange(int total, {int? lastPageOverride}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    interceptor = _PagedInterceptor(total, lastPageOverride: lastPageOverride);
    dio.interceptors.add(interceptor);
    repository = PropertyRepository(dio, sessionRoleFixture());
  }

  group('parc complet proposé au sélecteur de périmètre', () {
    test('un parc de 21 logements est rendu en entier', () async {
      // Le défaut : l'API retombe à 20 par page quand `per_page` est absent,
      // et le 21e logement n'apparaissait jamais dans le sélecteur — donc
      // impossible à confier à un gérant.
      arrange(21);

      final all = await repository.getAllProperties();

      expect(all.length, 21);
      expect(all.last.id, 'p-21');
    });

    test('la première requête demande déjà plus de 20 logements', () async {
      arrange(21);

      await repository.getAllProperties();

      expect(interceptor.requests.first.queryParameters['per_page'], 100);
      expect(interceptor.requests.first.queryParameters['page'], 1);
    });

    test('un parc de 250 logements tient en trois appels', () async {
      // Le coût annoncé : 100 par page, donc trois allers-retours. Le
      // vérifier fige le plafond, qu'un retour à 20 ferait exploser à treize.
      arrange(250);

      final all = await repository.getAllProperties();

      expect(all.length, 250);
      expect(interceptor.requests.length, 3);
    });

    test('un parc de 100 logements tient en un seul appel', () async {
      // Pile la taille d'une page : `hasMore` est faux, rien ne justifie un
      // second aller-retour à vide.
      arrange(100);

      final all = await repository.getAllProperties();

      expect(all.length, 100);
      expect(interceptor.requests.length, 1);
    });
  });

  group('bornes de la pagination', () {
    test('un parc d’un seul logement ne fait qu’un appel', () async {
      arrange(1);

      final all = await repository.getAllProperties();

      expect(all.single.id, 'p-1');
      expect(interceptor.requests.length, 1);
    });

    test('un parc vide rend une liste vide sans boucler', () async {
      arrange(0);

      final all = await repository.getAllProperties();

      expect(all, isEmpty);
      expect(interceptor.requests.length, 1);
    });

    test('un serveur qui annonce toujours une page suivante ne boucle pas', () {
      // `lastPage` restant hors d'atteinte, seule une page vide peut arrêter
      // la boucle. Sans ce garde-fou, l'écran se figerait sans fin.
      arrange(30, lastPageOverride: 9999);

      return expectLater(
        repository.getAllProperties().timeout(const Duration(seconds: 5)),
        completion(hasLength(30)),
      ).then((_) {
        // Une page pleine, puis une page vide qui interrompt : pas davantage.
        expect(interceptor.requests.length, 2);
      });
    });
  });

  group('filtre par résidence', () {
    test('le filtre accompagne chaque page demandée', () async {
      arrange(150);

      await repository.getAllProperties(residenceId: 'res-1');

      for (final request in interceptor.requests) {
        expect(request.queryParameters['residence_id'], 'res-1');
      }
      expect(interceptor.requests.length, 2);
    });
  });
}
