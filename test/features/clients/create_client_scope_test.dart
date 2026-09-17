import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/error/failures.dart';
import 'package:resi_africa/core/sync/sync_service.dart';
import 'package:resi_africa/features/clients/data/models/client_creation_result.dart';
import 'package:resi_africa/features/clients/data/repositories/clients_repository.dart';
import '../../support/session_role_fixture.dart';

/// Faux serveur : rend le statut et le corps demandés, sans réseau.
class _StubInterceptor extends Interceptor {
  _StubInterceptor(this.status, this.body);

  final int status;
  final Object? body;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.resolve(
      Response(requestOptions: options, statusCode: status, data: body),
    );
  }
}

ClientsRepository _repository(
  int status,
  Object? body, {
  String role = 'proprio',
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'));
  dio.interceptors.add(_StubInterceptor(status, body));
  return ClientsRepository(dio, sessionRoleFixture(role));
}

const _clientJson = {
  'id': 'cl-1',
  'full_name': 'Awa',
  'phone': '+2250700000000',
  'status': 'active',
};

void main() {
  group('création d’une fiche client', () {
    test('une fiche créée revient complète', () async {
      final repository = _repository(201, const {
        'data': _clientJson,
        'already_existed': false,
      });

      final result = await repository.create(
        fullName: 'Awa',
        phone: '+2250700000000',
      );

      expect(result.alreadyExisted, isFalse);
      expect(result.client, isNotNull);
      expect(result.client!.id, 'cl-1');
      expect(result.isOutOfScope, isFalse);
    });

    test('une fiche du périmètre déjà connue revient complète', () async {
      // Non-régression du propriétaire : le dédoublonnage par téléphone rend
      // la fiche existante, que l'écran propose de réutiliser.
      final repository = _repository(200, const {
        'data': _clientJson,
        'already_existed': true,
      });

      final result = await repository.create(
        fullName: 'Awa',
        phone: '+2250700000000',
      );

      expect(result.alreadyExisted, isTrue);
      expect(result.client, isNotNull);
      expect(result.client!.id, 'cl-1');
      expect(result.isOutOfScope, isFalse);
    });

    test('une fiche hors périmètre revient nue, sans lever', () async {
      // Le serveur accuse qu'il n'y a rien à créer sans livrer la fiche : le
      // gérant n'apprend rien d'un client qu'il ne sert pas. Avant correction,
      // le transtypage de `null` levait une TypeError, attrapée en
      // `AppFailure.unexpected` — le gérant lisait une erreur technique sur
      // une situation parfaitement normale.
      final repository = _repository(200, const {
        'data': null,
        'already_existed': true,
      }, role: 'gerant');

      final result = await repository.create(
        fullName: 'Awa',
        phone: '+2250700000000',
      );

      expect(result.alreadyExisted, isTrue);
      expect(result.client, isNull);
      expect(result.isOutOfScope, isTrue);
    });
  });

  group('refus de périmètre sur une fiche client', () {
    test('la saisie sort de la file au lieu de s’y rejouer', () {
      // Le serveur rendra la même réponse à chaque passe : laissée en file, la
      // réservation bloquerait tout ce qui la suit. `rejected` la retire de la
      // file sans la détruire — elle porte de l'argent encaissé au comptoir.
      expect(
        classifyFailure(
          AppFailure.forbidden(
            message: clientOutOfScopeMessage,
            code: 'client_out_of_scope',
          ),
        ),
        FailureDisposition.rejected,
      );
    });

    test('le message renvoie au propriétaire sans proposer de réessayer', () {
      // Le gérant ne peut rien seul : la seule issue passe par le
      // propriétaire. Suggérer un nouvel essai l'enverrait dans une boucle,
      // la réponse du serveur étant identique à chaque fois.
      expect(clientOutOfScopeMessage.toLowerCase(), contains('propriétaire'));
      expect(clientOutOfScopeMessage.toLowerCase(), isNot(contains('essay')));
    });
  });
}
