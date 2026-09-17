import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resi_africa/core/error/exception_mapper.dart';
import 'package:resi_africa/core/error/failures.dart';

/// Reponse d'erreur telle que l'API la renvoie : `{ code, message }`.
DioException _dioError(int status, Map<String, dynamic>? body) {
  final requestOptions = RequestOptions(path: '/api/v1/gerant/bookings');

  return DioException(
    requestOptions: requestOptions,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: requestOptions,
      statusCode: status,
      data: body,
    ),
  );
}

void main() {
  group('AppFailure.code', () {
    test('retient le code metier d’un 403', () {
      final failure = AppFailure.fromDio(
        _dioError(403, {
          'code': 'out_of_scope',
          'message': 'Ce logement ne fait pas partie de votre perimetre.',
        }),
      );

      expect(failure.code, 'out_of_scope');
      expect(failure.statusCode, 403);
    });

    test('retient le code metier d’un 409', () {
      final failure = AppFailure.fromDio(
        _dioError(409, {
          'code': 'booking_period_conflict',
          'message': 'Cette periode est deja reservee.',
        }),
      );

      expect(failure.code, 'booking_period_conflict');
      expect(failure.statusCode, 409);
    });

    test('retient le code metier d’un 422', () {
      // Les refus de validation en portent un aussi, et d'autres chantiers
      // s'en serviront : l'extraction ne doit pas etre reservee au 403.
      final failure = AppFailure.fromDio(
        _dioError(422, {
          'code': 'property_required',
          'errors': [
            {'field': 'property_id', 'message': 'Le logement est requis.'},
          ],
        }),
      );

      expect(failure.code, 'property_required');
    });

    test('retient le code metier d’un 404', () {
      final failure = AppFailure.fromDio(
        _dioError(404, {'code': 'booking_cancelled', 'message': 'Annulee.'}),
      );

      expect(failure.code, 'booking_cancelled');
    });

    test('vaut null quand l’API n’en fournit pas', () {
      // Les erreurs d'infrastructure — panne reseau, 500 nu — n'ont pas de
      // code metier. L'absence doit se lire sans lever.
      final failure = AppFailure.fromDio(_dioError(500, null));

      expect(failure.code, isNull);
    });

    test('vaut null sur une panne de transport', () {
      final failure = AppFailure.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ),
      );

      expect(failure.code, isNull);
    });

    test('ignore un code qui n’est pas une chaine', () {
      // Un corps mal forme ne doit pas faire lever la construction du refus :
      // la synchronisation perdrait la saisie au lieu de la rejouer.
      final failure = AppFailure.fromDio(_dioError(403, {'code': 42}));

      expect(failure.code, isNull);
      expect(failure.statusCode, 403);
    });

    test('ignore un corps qui n’est pas un objet', () {
      final failure = AppFailure.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/'),
            statusCode: 500,
            data: '<html>502 Bad Gateway</html>',
          ),
        ),
      );

      expect(failure.code, isNull);
      expect(failure.statusCode, 500);
    });

    test('le message affiche ne change pas', () {
      // L'ajout du code ne doit toucher aucun libelle deja montre a
      // l'utilisateur.
      final failure = AppFailure.fromDio(
        _dioError(403, {
          'code': 'out_of_scope',
          'message': 'Ce logement ne fait pas partie de votre perimetre.',
        }),
      );

      expect(
        failure.userMessage,
        'Ce logement ne fait pas partie de votre perimetre.',
      );
    });

    test('un refus construit sans code se comporte comme avant', () {
      expect(AppFailure.forbidden().userMessage, 'Acces refuse.');
      expect(AppFailure.forbidden().code, isNull);
      expect(AppFailure.notFound().userMessage, 'Ressource introuvable.');
      expect(AppFailure.unauthorized().statusCode, 401);
      expect(
        AppFailure.serverError(code: 409).userMessage,
        'Cette periode est deja reservee.',
      );
      expect(
        AppFailure.validation(errors: const {}).userMessage,
        'Les informations saisies ont ete refusees par le serveur.',
      );
    });
  });

  group('mapDioExceptionToFailure', () {
    // C'est ce chemin qu'emprunte `ReservationRepository`, donc celui dont la
    // synchronisation hors ligne depend reellement. `AppFailure.fromDio` ne
    // sert qu'a l'authentification : le couvrir seul aurait laisse le code
    // metier a null sur toute la file d'envoi.
    test('retient le code metier d’un 403', () {
      final failure = mapDioExceptionToFailure(
        _dioError(403, {
          'code': 'out_of_scope',
          'message': 'Ce logement ne fait pas partie de votre perimetre.',
        }),
      );

      expect(failure.code, 'out_of_scope');
      expect(failure.statusCode, 403);
    });

    test('retient le code metier d’un 409', () {
      final failure = mapDioExceptionToFailure(
        _dioError(409, {
          'code': 'booking_period_conflict',
          'message': 'Cette periode est deja reservee.',
        }),
      );

      expect(failure.code, 'booking_period_conflict');
      expect(failure.statusCode, 409);
    });

    test('vaut null quand l’API n’en fournit pas', () {
      expect(mapDioExceptionToFailure(_dioError(500, null)).code, isNull);
    });

    test('le message affiche ne change pas', () {
      final failure = mapDioExceptionToFailure(
        _dioError(403, {
          'code': 'out_of_scope',
          'message': 'Ce logement ne fait pas partie de votre perimetre.',
        }),
      );

      expect(
        failure.userMessage,
        'Ce logement ne fait pas partie de votre perimetre.',
      );
    });
  });
}
