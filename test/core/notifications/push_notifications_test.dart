import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/notifications/device_token_repository.dart';
import 'package:resi_africa/core/notifications/push_destination.dart';

/// Intercepte la requête composée, sans réseau.
class _CapturingInterceptor extends Interceptor {
  RequestOptions? captured;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    captured = options;
    handler.resolve(Response(requestOptions: options, statusCode: 204));
  }
}

void main() {
  group('DeviceTokenRepository', () {
    late _CapturingInterceptor interceptor;
    late DeviceTokenRepository repository;

    setUp(() {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      interceptor = _CapturingInterceptor();
      dio.interceptors.add(interceptor);
      repository = DeviceTokenRepository(dio);
    });

    test('enregistre l’appareil sur la route commune à tous les rôles', () async {
      await repository.register('fcm-token-123456789012345', platform: 'android');

      final request = interceptor.captured!;
      expect(request.method, 'POST');
      expect(request.path, endsWith('/api/v1/auth/device-tokens'));
      expect(request.data, {
        'token': 'fcm-token-123456789012345',
        'platform': 'android',
      });
    });

    test('retire l’appareil à la déconnexion', () async {
      await repository.unregister('fcm-token-123456789012345');

      final request = interceptor.captured!;
      expect(request.method, 'DELETE');
      expect(request.data, {'token': 'fcm-token-123456789012345'});
    });
  });

  group('PushDestination.fromData', () {
    test('une relance d’échéance ouvre les forfaits', () {
      expect(
        PushDestination.fromData({'type': 'subscription_expiry'}),
        PushDestination.subscription,
      );
    });

    test('un message du back-office n’ouvre rien de particulier', () {
      expect(PushDestination.fromData({'type': 'admin_message'}), isNull);
    });

    test('des données absentes ou inconnues sont ignorées', () {
      expect(PushDestination.fromData(const {}), isNull);
      expect(PushDestination.fromData({'type': 'autre'}), isNull);
    });
  });
}
