import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/session/session_role.dart';
import 'package:resi_africa/features/home/presentation/widgets/bottom_navigation/property_bottom_navigation_bar.dart';
import 'package:resi_africa/features/home/presentation/widgets/bottom_navigation/property_visibility_switch.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';
import 'package:resi_africa/features/property/presentation/screens/property_detail_screen.dart';

import '../../support/session_role_fixture.dart';

/// La bascule de mise en ligne appelle `publish`/`unpublish`, qui visent
/// `/proprio/...` en dur : un gérant n'en obtenait qu'un 403. Ces tests montent
/// l'écran réel — vérifier que `isGestureAllowed` rend `false` ne dirait rien
/// de ce que l'écran construit.
PropertyModel _property({bool isPublic = false}) {
  return PropertyModel(
    id: 'prop_1',
    ownerId: 'own_1',
    title: 'Villa Belvédère',
    description: 'Une belle villa avec vue sur la lagune.',
    propertyType: PropertyType.villa,
    status: PropertyStatus.published,
    address: const PropertyAddress(
      street: 'Rue des Jardins',
      city: 'Abidjan',
      latitude: 5.35,
      longitude: -3.99,
    ),
    details: const PropertyDetails(
      surfaceArea: 180,
      bedrooms: 4,
      bathrooms: 2,
      livingRooms: 1,
      kitchens: 1,
      parkingSpaces: 2,
    ),
    amenities: const {Amenity.wifi},
    // Sans image : la couverture distante n'a pas à être chargée en test.
    images: const [],
    pricing: const PropertyPricing(dailyPrice: 15000),
    availableFrom: DateTime(2025, 1, 1),
    isPublic: isPublic,
  );
}

Future<void> _pumpDetail(WidgetTester tester, String role) async {
  sl.registerSingleton<SessionRole>(sessionRoleFixture(role));
  await tester.pumpWidget(
    MaterialApp(home: PropertyDetailScreen(property: _property())),
  );
  await tester.pump();
}

void main() {
  setUp(() => GetIt.instance.reset());
  tearDown(() => GetIt.instance.reset());

  group('Fiche bien — mise en ligne de l’annonce', () {
    testWidgets('le propriétaire garde la bascule', (tester) async {
      await _pumpDetail(tester, 'proprio');

      expect(find.byType(PropertyVisibilitySwitch), findsOneWidget);
      expect(find.text('Hors ligne'), findsOneWidget);
    });

    testWidgets('le gérant ne voit pas la bascule', (tester) async {
      await _pumpDetail(tester, 'gerant');

      expect(find.byType(PropertyVisibilitySwitch), findsNothing);
      expect(find.text('Hors ligne'), findsNothing);
    });

    testWidgets('le gérant garde la modification du bien', (tester) async {
      // `PATCH /gerant/properties/:id/availability` lui reste ouvert : seule la
      // mise en ligne disparaît, pas la barre entière.
      await _pumpDetail(tester, 'gerant');

      expect(find.byType(PropertyBottomNavigationBar), findsOneWidget);
    });
  });

  group('PropertyBottomNavigationBar — construction directe', () {
    testWidgets('la bascule disparaît sur canChangeVisibility faux', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: PropertyBottomNavigationBar(
              onEditPressed: () {},
              isPublished: true,
              onVisibilityChanged: (_) {},
              canChangeVisibility: false,
            ),
          ),
        ),
      );

      expect(find.byType(PropertyVisibilitySwitch), findsNothing);
    });

    testWidgets('elle est présente par défaut', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: PropertyBottomNavigationBar(
              onEditPressed: () {},
              isPublished: true,
              onVisibilityChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(PropertyVisibilitySwitch), findsOneWidget);
    });
  });
}
