import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/auth/business_logic/owner_profile_cubit.dart';
import 'package:resi_africa/features/auth/business_logic/owner_profile_state.dart';
import 'package:resi_africa/features/auth/data/models/owner_profile_model.dart';
import 'package:resi_africa/features/home/presentation/widgets/tabs/profile_tab.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/skeletons/profile_skeleton.dart';

/// Cubit piloté par le test : évite le service locator et le réseau.
class _FakeCubit extends Cubit<OwnerProfileState>
    implements OwnerProfileCubit {
  _FakeCubit(super.initialState);

  @override
  Future<void> load() async {}

  @override
  Future<void> submit({
    required String fullName,
    required String phone,
    required IdDocumentType idDocumentType,
    required String idDocumentNumber,
    String? address,
    String? city,
    String? country,
    String? frontImagePath,
    String? backImagePath,
  }) async {}
}

OwnerProfileModel _profile({
  String fullName = 'Kouamé Jean-Baptiste',
  String? email = 'kouame.jb@gmail.com',
  String? phone = '+2250758123456',
  String? address = 'Cocody · Rue des Jardins',
  String? city = 'Abidjan',
  String? country = 'CI',
  IdDocumentType? idDocumentType = IdDocumentType.cni,
  String? idDocumentNumber = 'CI-AB-2019-12345',
  String? ownerStatus = 'active',
  bool isSubmitted = true,
}) {
  return OwnerProfileModel(
    fullName: fullName,
    email: email,
    phone: phone,
    address: address,
    city: city,
    country: country,
    idDocumentType: idDocumentType,
    idDocumentNumber: idDocumentNumber,
    ownerStatus: ownerStatus,
    isSubmitted: isSubmitted,
  );
}

Future<void> _pump(WidgetTester tester, OwnerProfileState state) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<OwnerProfileCubit>.value(
        value: _FakeCubit(state),
        // L'écran racine crée son propre provider via le service locator :
        // on monte directement la vue interne, exposée pour les tests.
        child: const ProfileView(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('ProfileTab — états', () {
    testWidgets('affiche un squelette pendant le chargement', (tester) async {
      await _pump(tester, const OwnerProfileLoading());
      expect(find.byType(ProfileSkeleton), findsOneWidget);
    });

    testWidgets('propose de réessayer si le profil est introuvable', (
      tester,
    ) async {
      await _pump(tester, const OwnerProfileError('Réseau indisponible'));

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Réseau indisponible'), findsOneWidget);
    });

    testWidgets('conserve le dossier en cache malgré une erreur', (
      tester,
    ) async {
      await _pump(
        tester,
        OwnerProfileError('Réseau indisponible', profile: _profile()),
      );

      // Un profil connu vaut mieux qu'un écran d'erreur : il reste affiché.
      expect(find.byType(ErrorState), findsNothing);
      // Le nom paraît deux fois : en en-tête, puis en ligne « Nom complet ».
      expect(find.text('Kouamé Jean-Baptiste'), findsNWidgets(2));
    });
  });

  group('ProfileTab — données réelles', () {
    testWidgets('affiche les informations du gestionnaire', (tester) async {
      await _pump(tester, OwnerProfileReady(_profile()));

      expect(find.text('Kouamé Jean-Baptiste'), findsNWidgets(2));
      expect(find.text('kouame.jb@gmail.com'), findsOneWidget);
      // Le code ISO2 stocké est rendu sous son libellé.
      expect(
        find.text('Propriétaire · Abidjan, Côte d\'Ivoire'),
        findsOneWidget,
      );
    });

    testWidgets('compose la pièce d’identité', (tester) async {
      await _pump(tester, OwnerProfileReady(_profile()));

      expect(
        find.text('Carte nationale d’identité • CI-AB-2019-12345'),
        findsOneWidget,
      );
    });

    testWidgets('remet le téléphone en forme nationale', (tester) async {
      await _pump(tester, OwnerProfileReady(_profile()));

      // Stocké en E.164, affiché sans indicatif.
      expect(find.textContaining('07 58 12'), findsOneWidget);
      expect(find.textContaining('+225'), findsNothing);
    });

    testWidgets('accepte un pays stocké sous son nom anglais', (tester) async {
      // Dossiers déposés avant que le client ne stocke le code ISO2.
      await _pump(
        tester,
        OwnerProfileReady(_profile(country: 'Ivory Coast')),
      );

      expect(
        find.text('Propriétaire · Abidjan, Côte d\'Ivoire'),
        findsOneWidget,
      );
      expect(find.textContaining('+225'), findsNothing);
    });

    testWidgets('omet les champs absents plutôt que de les vider', (
      tester,
    ) async {
      await _pump(
        tester,
        OwnerProfileReady(
          _profile(
            email: null,
            phone: null,
            idDocumentType: null,
            idDocumentNumber: null,
          ),
        ),
      );

      expect(find.text('Email'), findsNothing);
      expect(find.text('Téléphone'), findsNothing);
      expect(find.text('Pièce d’identité'), findsNothing);
      // Le nom, lui, reste présent.
      expect(find.text('Nom complet'), findsOneWidget);
    });

    testWidgets('replie sur les initiales sans avatar', (tester) async {
      await _pump(tester, OwnerProfileReady(_profile()));

      expect(find.text('KJ'), findsOneWidget);
    });
  });

  group('ProfileTab — statut du dossier', () {
    testWidgets('un dossier validé n’offre pas d’action', (tester) async {
      await _pump(tester, OwnerProfileReady(_profile()));

      expect(find.text('Dossier validé'), findsOneWidget);
      expect(find.text('Compléter'), findsNothing);
    });

    testWidgets('un dossier à déposer propose de le compléter', (tester) async {
      await _pump(
        tester,
        OwnerProfileReady(
          _profile(ownerStatus: 'pending', isSubmitted: false),
        ),
      );

      expect(find.text('Dossier à compléter'), findsOneWidget);
      expect(find.text('Compléter'), findsOneWidget);
    });

    testWidgets('un refus affiche le motif du serveur', (tester) async {
      await _pump(
        tester,
        OwnerProfileReady(
          OwnerProfileModel(
            fullName: 'Awa Koné',
            isSubmitted: true,
            ownerStatus: 'rejected',
            rejectionReason: 'Photo illisible',
          ),
        ),
      );

      expect(find.text('Photo illisible'), findsOneWidget);
    });
  });
}
