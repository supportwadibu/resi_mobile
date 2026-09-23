import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/session/session_role.dart';
import 'package:resi_africa/features/auth/data/repositories/owner_profile_repository.dart';
import 'package:resi_africa/features/auth/data/services/property_manager_service.dart';
import 'package:resi_africa/features/auth/presentation/widgets/profile_completion_banner.dart';

import '../../support/session_role_fixture.dart';

/// Faux serveur du dossier de validation, qui mémorise les chemins appelés.
class _BannerInterceptor extends Interceptor {
  final List<String> paths = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    paths.add(options.path);

    // Dossier non déposé : le cas où le bandeau s'affiche chez un
    // propriétaire. C'est celui qui rend visible une bifurcation manquante.
    handler.resolve(
      Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'data': {'full_name': 'Awa Koné', 'is_submitted': false},
        },
      ),
    );
  }
}

Future<_BannerInterceptor> _pump(WidgetTester tester, String role) async {
  final interceptor = _BannerInterceptor();
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..interceptors.add(interceptor);

  // Le bandeau lit le conteneur : contrairement à `ProfileView`, il n'a pas de
  // cubit injectable. Le conteneur est donc câblé, puis vidé.
  await sl.reset();
  sl.registerSingleton<SessionRole>(sessionRoleFixture(role));
  sl.registerSingleton<PropertyManagerService>(
    PropertyManagerService(MemoryLocalStorage(), OwnerProfileRepository(dio)),
  );

  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: ProfileCompletionBanner())),
  );
  await tester.pumpAndSettle();

  return interceptor;
}

void main() {
  tearDown(() async => sl.reset());

  group('ProfileCompletionBanner — bifurcation par rôle', () {
    testWidgets('le propriétaire voit l’invitation à finaliser', (
      tester,
    ) async {
      final interceptor = await _pump(tester, 'proprio');

      expect(find.text('Finalisez votre inscription'), findsOneWidget);
      expect(
        interceptor.paths.where((p) => p.contains('/proprio/profile')),
        hasLength(1),
      );
    });

    testWidgets('le gérant n’appelle pas /proprio/profile', (tester) async {
      final interceptor = await _pump(tester, 'gerant');

      // Le 403 se repliait sur `null` et masquait déjà le bandeau : le défaut
      // n'était pas visible à l'écran, mais coûtait un appel voué à l'échec à
      // chaque ouverture de l'accueil.
      expect(interceptor.paths, isEmpty);
      expect(find.text('Finalisez votre inscription'), findsNothing);
    });
  });
}
