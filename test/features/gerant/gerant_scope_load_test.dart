import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/features/gerant/business_logic/gerant_scope_cubit.dart';
import 'package:resi_africa/features/gerant/data/repositories/gerant_admin_repository.dart';
import 'package:resi_africa/features/property/data/repositories/property_repository.dart';
import 'package:resi_africa/features/residence/data/repositories/residence_repository.dart';

import '../../support/session_role_fixture.dart';

/// Faux serveur du parc : une résidence, et le nombre de logements demandé.
///
/// Route sur le chemin, chaque repository interrogeant le sien. Les délais
/// sont ceux qui rendent le parallélisme observable : si le cubit enchaînait
/// les appels, le chargement durerait leur somme et non leur maximum.
class _ParcInterceptor extends Interceptor {
  _ParcInterceptor({required this.propertyCount, this.latency = Duration.zero});

  final int propertyCount;
  final Duration latency;

  /// Instants d'arrivée de chaque requête, pour distinguer un lancement
  /// simultané d'un enchaînement.
  final List<DateTime> startedAt = [];
  final List<String> paths = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    startedAt.add(DateTime.now());
    paths.add(options.path);

    Future<void>.delayed(latency, () {
      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: _bodyFor(options),
        ),
      );
    });
  }

  Map<String, dynamic> _bodyFor(RequestOptions options) {
    if (options.path.contains('/residences')) {
      return {
        'data': [
          {'id': 'res-1', 'name': 'Resi Cocody'},
        ],
        'meta': {'total': 1, 'perPage': 100, 'currentPage': 1, 'lastPage': 1},
      };
    }

    if (options.path.contains('/properties')) {
      final page = (options.queryParameters['page'] as int?) ?? 1;
      final perPage = (options.queryParameters['per_page'] as int?) ?? 20;
      final start = (page - 1) * perPage;
      final end = (start + perPage).clamp(0, propertyCount);

      return {
        'data': [
          for (var i = start; i < end; i++)
            {
              'id': 'p-${i + 1}',
              'title': 'Logement ${i + 1}',
              'unit_label': 'Studio ${i + 1}',
              'residence_id': 'res-1',
            },
        ],
        'meta': {
          'total': propertyCount,
          'perPage': perPage,
          'currentPage': page,
          'lastPage': propertyCount == 0
              ? 1
              : ((propertyCount + perPage - 1) ~/ perPage),
        },
      };
    }

    return {'data': const <dynamic>[]};
  }
}

void main() {
  late _ParcInterceptor interceptor;
  late GerantScopeCubit cubit;

  void arrange({required int propertyCount, Duration latency = Duration.zero}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    interceptor = _ParcInterceptor(
      propertyCount: propertyCount,
      latency: latency,
    );
    dio.interceptors.add(interceptor);

    final role = sessionRoleFixture();
    cubit = GerantScopeCubit(
      GerantAdminRepository(dio),
      ResidenceRepository(dio, role),
      PropertyRepository(dio, role),
    );
  }

  tearDown(() => cubit.close());

  group('le sélecteur reçoit tout le parc', () {
    test('un parc de 21 logements est proposé en entier', () async {
      // Le défaut : la liste non paginée s'arrêtait aux 20 premiers, et le
      // propriétaire ne pouvait pas confier son 21e logement à un gérant.
      arrange(propertyCount: 21);

      await cubit.load();

      final state = cubit.state as GerantScopeLoaded;
      expect(state.totalCount, 21);

      final ids = state.groups.single.properties.map((p) => p.id).toSet();
      expect(ids.contains('p-21'), isTrue);
    });

    test('deux résidences de 60 logements passent entièrement', () async {
      // Le cas que le propriétaire décrit : une résidence de dix logements
      // passait déjà, deux résidences ne passaient plus.
      arrange(propertyCount: 120);

      await cubit.load();

      expect((cubit.state as GerantScopeLoaded).totalCount, 120);
    });

    test('un parc d’un seul logement reste proposé', () async {
      arrange(propertyCount: 1);

      await cubit.load();

      expect((cubit.state as GerantScopeLoaded).totalCount, 1);
    });

    test('un parc vide charge sans erreur', () async {
      // Une résidence sans logement est écartée de l'affichage : l'écran est
      // vide, mais chargé — pas en erreur.
      arrange(propertyCount: 0);

      await cubit.load();

      final state = cubit.state as GerantScopeLoaded;
      expect(state.totalCount, 0);
      expect(state.groups, isEmpty);
    });
  });

  group('parallélisme des appels', () {
    test('résidences, logements et gérant partent ensemble', () async {
      // Le chargement enchaîné triplerait l'attente sur les connexions lentes
      // du terrain. Les trois premières requêtes doivent donc partir avant
      // qu'aucune n'ait répondu.
      arrange(propertyCount: 10, latency: const Duration(milliseconds: 120));

      await cubit.load(gerantId: 'ger-1');

      expect(interceptor.paths.length, greaterThanOrEqualTo(3));

      final firstThree = interceptor.startedAt.take(3).toList();
      final ecart = firstThree.last.difference(firstThree.first);

      // Enchaînés, deux départs seraient séparés d'au moins une latence.
      expect(ecart, lessThan(const Duration(milliseconds: 120)));
    });

    test('les pages suivantes, elles, s’enchaînent', () async {
      // La pagination reste en série : la page 2 ne peut partir qu'une fois la
      // page 1 connue, son existence même en dépendant.
      arrange(propertyCount: 150);

      await cubit.load();

      final propertyPaths = interceptor.paths
          .where((p) => p.contains('/properties'))
          .toList();
      expect(propertyPaths.length, 2);
    });
  });
}
