import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/shared/widgets/loading_shimmer.dart';
import 'package:resi_africa/shared/widgets/skeletons/form_skeleton.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';

void main() {
  group('ShimmerEffect', () {
    testWidgets('anime sans lever et se dispose proprement', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerEffect(child: LoadingShimmer(height: 20)),
          ),
        ),
      );

      // L'animation tourne en boucle : on avance de quelques trames pour
      // vérifier qu'aucune n'échoue.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(LoadingShimmer), findsOneWidget);

      // Le contrôleur répétant indéfiniment, il doit être libéré au démontage
      // sans laisser de timer actif.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(find.byType(ShimmerEffect), findsNothing);
    });
  });

  group('OwnerProfileFormSkeleton', () {
    testWidgets('reprend la structure de l’étape 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OwnerProfileFormSkeleton()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Nom, pays, ville, adresse, téléphone.
      expect(find.byType(FieldSkeleton), findsNWidgets(5));
    });

    testWidgets('ajoute l’encart d’introduction en onboarding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OwnerProfileFormSkeleton(showIntro: true)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FieldSkeleton), findsNWidgets(5));
      // L'encart s'ajoute aux blocs déjà présents sans squelette de champ.
      expect(find.byType(LoadingShimmer), findsAtLeast(13));
    });
  });

  group('Squelettes de liste', () {
    testWidgets('PropertyListSkeleton rend le nombre demandé', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PropertyListSkeleton(itemCount: 3)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PropertyCardSkeleton), findsNWidgets(3));
    });

    testWidgets('le squelette ne défile pas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SimpleListSkeleton())),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isA<NeverScrollableScrollPhysics>());
    });

    // Les squelettes de liste sont posés dans des colonnes défilantes
    // (`home_tab`, `reservation_tab`) : sans `shrinkWrap`, le `ListView`
    // recevait une hauteur non bornée et la mise en page échouait.
    testWidgets('PropertyListSkeleton tient dans une colonne défilante', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [PropertyListSkeleton(itemCount: 2)],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(PropertyCardSkeleton), findsNWidgets(2));
    });

    testWidgets('SimpleListSkeleton tient dans une colonne défilante', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(children: [SimpleListSkeleton(itemCount: 3)]),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
