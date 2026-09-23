import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/router/role_guard.dart';
import 'package:resi_africa/features/auth/business_logic/owner_profile_cubit.dart';
import 'package:resi_africa/features/auth/data/repositories/owner_profile_repository.dart';
import 'package:resi_africa/features/auth/data/services/property_manager_service.dart';
import 'package:resi_africa/features/gerant/data/repositories/gerant_repository.dart';
import 'package:resi_africa/features/home/presentation/widgets/tabs/profile_tab.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';

import '../../support/session_role_fixture.dart';

/// Faux serveur du profil, qui **mémorise chaque chemin appelé**.
///
/// La liste des chemins est le cœur de ces tests : vérifier que le cubit rend
/// la bonne donnée ne dit rien de la route qu'il a interrogée, et c'est
/// précisément l'appel à `/proprio/profile` qui mettait l'écran du gérant en
/// erreur. Un test qui ne regarderait que l'affichage resterait vert si la
/// bifurcation disparaissait mais que le serveur répondait quand même.
class _ProfileInterceptor extends Interceptor {
  _ProfileInterceptor({
    this.managerBody,
    this.ownerBody,
    this.forbidOwner = true,
    this.failManager = false,
  });

  /// Corps servi par `GET /gerant/profile`.
  final Map<String, dynamic>? managerBody;

  /// Le relevé gérant échoue-t-il ? Simule une panne réseau côté serveur.
  final bool failManager;

  /// Corps servi par `GET /proprio/profile`.
  final Map<String, dynamic>? ownerBody;

  /// Le préfixe propriétaire répond-il 403 ? C'est ce que fait le serveur face
  /// à un gérant : `middleware.role(['proprio'])` le refuse avant le contrôleur.
  final bool forbidOwner;

  final List<String> paths = [];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    paths.add(options.path);

    if (options.path.contains('/gerant/profile')) {
      if (failManager) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        );
        return;
      }

      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'data': managerBody},
        ),
      );
      return;
    }

    if (options.path.contains('/proprio/profile')) {
      if (forbidOwner) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 403,
              data: {'error': 'forbidden_role'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return;
      }

      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'data': ownerBody},
        ),
      );
      return;
    }

    handler.next(options);
  }
}

/// Dossier gérant tel que servi par `GET /api/v1/gerant/profile` — la forme
/// exacte de `ManagerDto`.
Map<String, dynamic> _managerDto({
  String fullName = 'Awa Koné',
  String? email = 'awa.kone@gmail.com',
  String? phone,
  bool isActive = true,
  List<String> propertyIds = const ['prop-1', 'prop-2'],
}) {
  return {
    '_id': 'ger-1',
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'is_active': isActive,
    'property_ids': propertyIds,
    'created_at': '2026-01-15T10:00:00.000Z',
  };
}

/// Dossier propriétaire tel que servi par `GET /api/v1/proprio/profile`.
Map<String, dynamic> _ownerDto() {
  return {
    'full_name': 'Kouamé Jean-Baptiste',
    'email': 'kouame.jb@gmail.com',
    'phone': '+2250758123456',
    'address': 'Rue des Jardins',
    'city': 'Abidjan',
    'country': 'CI',
    'id_document_type': 'cni',
    'id_document_number': 'CI-AB-2019-12345',
    'owner_status': 'active',
    'is_submitted': true,
  };
}

/// Monte l'écran avec le **câblage réel** : vrai cubit, vrais repositories,
/// seul le transport est simulé.
///
/// C'est le point de ces tests. Un cubit factice vérifierait la règle sans
/// vérifier que l'écran l'emprunte — le défaut corrigé ici était justement
/// dans le montage, pas dans une règle.
Future<_ProfileInterceptor> _pump(
  WidgetTester tester, {
  required String role,
  Map<String, dynamic>? managerBody,
  Map<String, dynamic>? ownerBody,
  bool forbidOwner = true,
  bool failManager = false,
}) async {
  final interceptor = _ProfileInterceptor(
    managerBody: managerBody ?? _managerDto(),
    ownerBody: ownerBody ?? _ownerDto(),
    forbidOwner: forbidOwner,
    failManager: failManager,
  );

  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
    ..interceptors.add(interceptor);

  final session = sessionRoleFixture(role);

  final cubit = OwnerProfileCubit(
    PropertyManagerService(MemoryLocalStorage(), OwnerProfileRepository(dio)),
    GerantRepository(dio, session),
    () => session.value,
  );

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<OwnerProfileCubit>.value(
        value: cubit..load(),
        child: const ProfileView(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return interceptor;
}

void main() {
  group('ProfileTab — gérant', () {
    testWidgets('obtient son profil sans erreur', (tester) async {
      await _pump(tester, role: 'gerant');

      expect(find.byType(ErrorState), findsNothing);
      // Le nom paraît deux fois : en en-tête, puis en ligne « Nom complet ».
      expect(find.text('Awa Koné'), findsNWidgets(2));
      expect(find.text('awa.kone@gmail.com'), findsOneWidget);
    });

    testWidgets('n’appelle jamais /proprio/profile', (tester) async {
      final interceptor = await _pump(tester, role: 'gerant');

      expect(
        interceptor.paths.any((p) => p.contains('/proprio/')),
        isFalse,
        reason: 'le préfixe propriétaire répond 403 au gérant',
      );
      expect(
        interceptor.paths.where((p) => p.contains('/gerant/profile')),
        hasLength(1),
      );
    });

    testWidgets('annonce son périmètre plutôt qu’une ville', (tester) async {
      await _pump(tester, role: 'gerant');

      expect(find.text('Gérant · 2 logements'), findsOneWidget);
      // Le compte gérant ne porte pas de ville : rien ne doit l'annoncer
      // propriétaire non plus.
      expect(find.textContaining('Propriétaire'), findsNothing);
    });

    testWidgets('un périmètre vide se dit, il ne se tait pas', (tester) async {
      await _pump(
        tester,
        role: 'gerant',
        managerBody: _managerDto(propertyIds: const []),
      );

      expect(find.text('Gérant · aucun logement confié'), findsOneWidget);
    });

    testWidgets('accorde le singulier sur un seul logement', (tester) async {
      await _pump(
        tester,
        role: 'gerant',
        managerBody: _managerDto(propertyIds: const ['prop-1']),
      );

      expect(find.text('Gérant · 1 logement'), findsOneWidget);
    });

    testWidgets('n’affiche aucun bloc propriétaire à vide', (tester) async {
      await _pump(tester, role: 'gerant');

      // Le dossier de validation n'a pas d'objet : ni son bandeau, ni son
      // invitation à déposer une pièce d'identité.
      expect(find.text('Dossier validé'), findsNothing);
      expect(find.text('Dossier à compléter'), findsNothing);
      expect(find.text('Compléter'), findsNothing);

      // Ni pièce d'identité, ni adresse : des notions propriétaires que
      // `GerantAccountModel` ne porte pas.
      expect(find.text('Pièce d’identité'), findsNothing);
      expect(find.text('Adresse'), findsNothing);

      // Une coordonnée absente disparaît plutôt que de s'afficher vide.
      expect(find.text('Téléphone'), findsNothing);
    });

    testWidgets('montre l’état réel de son compte', (tester) async {
      await _pump(tester, role: 'gerant');
      expect(find.text('Compte actif'), findsOneWidget);
    });

    testWidgets('un compte suspendu le dit, sans action impossible', (
      tester,
    ) async {
      await _pump(
        tester,
        role: 'gerant',
        managerBody: _managerDto(isActive: false),
      );

      expect(find.text('Compte suspendu'), findsOneWidget);
      // Le rétablissement relève du propriétaire : aucun bouton ne doit
      // laisser croire au gérant qu'il peut agir.
      expect(find.text('Compléter'), findsNothing);
    });

    testWidgets('ne propose pas de modifier ses informations', (tester) async {
      await _pump(tester, role: 'gerant');

      // L'écran d'édition est le formulaire du dossier propriétaire, fermé au
      // gérant par `OwnerRouteGuard` : l'entrée mènerait à une redirection.
      expect(find.text('Modifier mes informations'), findsNothing);
      expect(find.text('Mes gérants'), findsNothing);
    });

    testWidgets('garde l’assistance et la déconnexion', (tester) async {
      await _pump(tester, role: 'gerant');

      expect(find.text('Aide & support'), findsOneWidget);
      expect(find.text('Se déconnecter'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('un échec du relevé gérant reste rattrapable', (tester) async {
      await _pump(tester, role: 'gerant', failManager: true);

      // Le gérant n'a rien à déposer : contrairement au propriétaire, dont
      // l'échec ouvre un formulaire vide, il lui faut de quoi réessayer.
      expect(find.byType(ErrorState), findsOneWidget);
    });
  });

  group('ProfileTab — propriétaire inchangé', () {
    testWidgets('lit toujours son dossier sur /proprio/profile', (
      tester,
    ) async {
      final interceptor = await _pump(
        tester,
        role: 'proprio',
        forbidOwner: false,
      );

      expect(
        interceptor.paths.where((p) => p.contains('/proprio/profile')),
        hasLength(1),
      );
      expect(
        interceptor.paths.any((p) => p.contains('/gerant/')),
        isFalse,
        reason: 'le relevé gérant n’a pas de sens pour un propriétaire',
      );
    });

    testWidgets('garde ses blocs propriétaire', (tester) async {
      await _pump(tester, role: 'proprio', forbidOwner: false);

      expect(find.text('Kouamé Jean-Baptiste'), findsNWidgets(2));
      expect(find.text('Propriétaire · Abidjan, Côte d\'Ivoire'), findsOneWidget);
      expect(
        find.text('Carte nationale d’identité • CI-AB-2019-12345'),
        findsOneWidget,
      );
      expect(find.text('Dossier validé'), findsOneWidget);
    });

    testWidgets('garde ses entrées de menu', (tester) async {
      await _pump(tester, role: 'proprio', forbidOwner: false);

      expect(find.text('Modifier mes informations'), findsOneWidget);
      expect(find.text('Mes gérants'), findsOneWidget);
      expect(find.text('Se déconnecter'), findsOneWidget);
    });
  });

  group('ProfileTab — déconnexion des deux rôles', () {
    // Le bouton et sa confirmation, non la purge elle-même : celle-ci est
    // vérifiée par `auth_service_logout_test`. Ce qui se perdrait ici, c'est
    // le câblage — un contenu gérant écrit à part pourrait fort bien oublier
    // l'entrée, ou la brancher sur un second exemplaire du dialogue.
    for (final role in ['proprio', 'gerant']) {
      testWidgets('$role : l’entrée ouvre la confirmation', (tester) async {
        await _pump(tester, role: role, forbidOwner: role == 'gerant');

        // L'entrée est en bas d'un contenu défilant : sans ce défilement, le
        // tap porte à côté et le test échouerait pour la mauvaise raison.
        await tester.scrollUntilVisible(
          find.text('Se déconnecter'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Se déconnecter'));
        await tester.pumpAndSettle();

        expect(
          find.text('Voulez-vous vraiment quitter votre session ?'),
          findsOneWidget,
        );

        // Refermée sans rien casser : `AuthService` n'est pas enregistré dans
        // ce test, et confirmer chercherait le conteneur.
        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();
      });
    }
  });

  group('role_guard — édition du profil', () {
    test('le geste est fermé au gérant', () {
      expect(isGestureAllowed('gerant', 'profile_edit'), isFalse);
    });

    test('le propriétaire le conserve', () {
      expect(isGestureAllowed('proprio', 'profile_edit'), isTrue);
    });
  });
}
