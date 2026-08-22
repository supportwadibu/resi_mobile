import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/auth/data/models/owner_profile_model.dart';
import 'package:resi_africa/features/auth/presentation/widgets/owner_profile/components/owner_profile_header.dart';

OwnerProfileModel _profile({
  String fullName = 'Awa Koné',
  String? email = 'awa@example.ci',
  String? avatarUrl,
  String? ownerStatus = 'pending',
  bool isSubmitted = false,
}) {
  return OwnerProfileModel(
    fullName: fullName,
    email: email,
    avatarUrl: avatarUrl,
    ownerStatus: ownerStatus,
    isSubmitted: isSubmitted,
  );
}

Future<void> _pump(WidgetTester tester, OwnerProfileModel profile) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: OwnerProfileHeader(profile: profile))),
  );
  await tester.pump();
}

void main() {
  group('OwnerProfileHeader — données réelles', () {
    testWidgets('affiche le nom et l’e-mail du gestionnaire', (tester) async {
      await _pump(tester, _profile());

      expect(find.text('Awa Koné'), findsOneWidget);
      expect(find.text('awa@example.ci'), findsOneWidget);
    });

    testWidgets('omet l’e-mail absent plutôt que d’afficher un vide', (
      tester,
    ) async {
      await _pump(tester, _profile(email: null));

      expect(find.text('Awa Koné'), findsOneWidget);
      // Seuls le nom et le statut subsistent.
      expect(find.text(''), findsNothing);
    });

    testWidgets('replie sur les initiales sans avatar', (tester) async {
      await _pump(tester, _profile());

      expect(find.text('AK'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('un nom en un seul mot donne une initiale', (tester) async {
      await _pump(tester, _profile(fullName: 'Awa'));

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('un nom vide ne fait pas planter le rendu', (tester) async {
      await _pump(tester, _profile(fullName: ''));

      expect(find.text('Sans nom'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('OwnerStatusBadge — statut réel du dossier', () {
    testWidgets('dossier non déposé', (tester) async {
      await _pump(tester, _profile(isSubmitted: false));
      expect(find.text('Dossier à compléter'), findsOneWidget);
    });

    testWidgets('dossier déposé, en attente d’examen', (tester) async {
      await _pump(tester, _profile(isSubmitted: true));
      expect(find.text('En cours de vérification'), findsOneWidget);
    });

    testWidgets('dossier validé', (tester) async {
      await _pump(
        tester,
        _profile(ownerStatus: 'active', isSubmitted: true),
      );
      expect(find.text('Dossier validé'), findsOneWidget);
    });

    testWidgets('dossier refusé', (tester) async {
      await _pump(
        tester,
        _profile(ownerStatus: 'rejected', isSubmitted: true),
      );
      expect(find.text('Dossier refusé'), findsOneWidget);
    });

    testWidgets('compte suspendu', (tester) async {
      await _pump(
        tester,
        _profile(ownerStatus: 'suspended', isSubmitted: true),
      );
      expect(find.text('Compte suspendu'), findsOneWidget);
    });
  });

  group('OwnerProfileModel — statuts dérivés', () {
    test('isUnderReview exige un dépôt effectif', () {
      expect(_profile(isSubmitted: true).isUnderReview, isTrue);
      // `pending` sans dépôt : le dossier n'a pas encore été transmis.
      expect(_profile(isSubmitted: false).isUnderReview, isFalse);
      expect(
        _profile(ownerStatus: 'active', isSubmitted: true).isUnderReview,
        isFalse,
      );
    });

    test('les statuts serveur sont reconnus', () {
      expect(_profile(ownerStatus: 'active').isValidated, isTrue);
      expect(_profile(ownerStatus: 'rejected').isRejected, isTrue);
      expect(_profile(ownerStatus: 'suspended').isSuspended, isTrue);
    });

    test('un statut inconnu ne prétend rien', () {
      final unknown = _profile(ownerStatus: 'zzz');
      expect(unknown.isValidated, isFalse);
      expect(unknown.isRejected, isFalse);
      expect(unknown.isSuspended, isFalse);
    });
  });
}
