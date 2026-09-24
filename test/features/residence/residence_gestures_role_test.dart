import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/session/session_role.dart';
import 'package:resi_africa/features/residence/business_logic/residence_cubit.dart';
import 'package:resi_africa/features/residence/business_logic/residence_detail_cubit.dart';
import 'package:resi_africa/features/residence/business_logic/residence_detail_state.dart';
import 'package:resi_africa/features/residence/business_logic/residence_state.dart';
import 'package:resi_africa/features/residence/data/models/residence_model.dart';
import 'package:resi_africa/features/residence/presentation/screens/residence_detail_screen.dart';
import 'package:resi_africa/features/residence/presentation/screens/residence_screen.dart';

import '../../support/session_role_fixture.dart';

/// Ces tests montent les écrans **réels**, pas une vue interne : c'est le
/// câblage qui est en cause, pas la règle. `isGestureAllowed` peut rendre la
/// bonne valeur pendant que le widget continue de construire le bouton — c'est
/// exactement le défaut que ce chantier corrige.
///
/// Les écrans lisent `sl<SessionRole>()` et créent leur cubit par le service
/// locator : le test y dépose une session et des cubits muets, sans réseau.
class _FakeResidenceCubit extends Cubit<ResidenceState>
    implements ResidenceCubit {
  _FakeResidenceCubit(super.initialState);

  @override
  Future<void> load() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeResidenceDetailCubit extends Cubit<ResidenceDetailState>
    implements ResidenceDetailCubit {
  _FakeResidenceDetailCubit(super.initialState);

  @override
  Future<void> load(String id) async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _residence = const ResidenceModel(
  id: 'res-1',
  name: 'Resi Adja',
  address: ResidenceAddress(street: 'Rue des Jardins', city: 'Abidjan'),
  unitsCount: 3,
);

/// Dépose dans le locator ce que les écrans y cherchent, pour un rôle donné.
void _register(String role, {List<ResidenceModel> items = const []}) {
  sl.registerSingleton<SessionRole>(sessionRoleFixture(role));
  sl.registerFactory<ResidenceCubit>(
    () => _FakeResidenceCubit(ResidenceLoaded(items)),
  );
  sl.registerFactory<ResidenceDetailCubit>(
    () =>
        _FakeResidenceDetailCubit(ResidenceDetailLoaded(residence: _residence)),
  );
}

Future<void> _pumpList(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: ResidenceScreen()));
  await tester.pump();
}

Future<void> _pumpDetail(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: ResidenceDetailScreen(residenceId: 'res-1')),
  );
  await tester.pump();
}

void main() {
  setUp(() => GetIt.instance.reset());
  tearDown(() => GetIt.instance.reset());

  group('Liste des résidences — bouton de création', () {
    testWidgets('le propriétaire garde le bouton +', (tester) async {
      _register('proprio', items: [_residence]);
      await _pumpList(tester);

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('le gérant ne voit pas le bouton +', (tester) async {
      // `/gerant/residences` n'expose qu'un `GET` : la route de création est
      // gardée et renvoyait le gérant à l'accueil sans un mot.
      _register('gerant', items: [_residence]);
      await _pumpList(tester);

      expect(find.byIcon(Icons.add_rounded), findsNothing);
    });
  });

  group('Liste des résidences — suppression', () {
    testWidgets('le propriétaire garde la suppression', (tester) async {
      _register('proprio', items: [_residence]);
      await _pumpList(tester);

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('le gérant ne voit pas la suppression', (tester) async {
      // Elle menait à une confirmation suivie d'un 404.
      _register('gerant', items: [_residence]);
      await _pumpList(tester);

      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    });
  });

  group('Liste des résidences — état vide', () {
    testWidgets('le propriétaire est invité à créer', (tester) async {
      _register('proprio');
      await _pumpList(tester);

      expect(find.text('Créer une résidence'), findsOneWidget);
    });

    testWidgets('le gérant garde l’explication, sans l’invitation', (
      tester,
    ) async {
      _register('gerant');
      await _pumpList(tester);

      expect(find.text('Aucune résidence'), findsOneWidget);
      expect(find.text('Créer une résidence'), findsNothing);
    });
  });

  group('Fiche résidence — modification', () {
    testWidgets('le propriétaire garde « Modifier »', (tester) async {
      _register('proprio');
      await _pumpDetail(tester);

      expect(find.text('Modifier'), findsOneWidget);
    });

    testWidgets('le gérant ne voit pas « Modifier »', (tester) async {
      _register('gerant');
      await _pumpDetail(tester);

      expect(find.text('Modifier'), findsNothing);
    });
  });

  group('Fiche résidence — rattachement d’un logement', () {
    testWidgets('le propriétaire garde « Rattacher »', (tester) async {
      _register('proprio');
      await _pumpDetail(tester);

      expect(find.text('Rattacher'), findsOneWidget);
    });

    testWidgets('le gérant ne voit pas « Rattacher »', (tester) async {
      // Le rattachement écrit sur la résidence, que le gérant ne façonne pas.
      _register('gerant');
      await _pumpDetail(tester);

      expect(find.text('Rattacher'), findsNothing);
      // La liste des logements, elle, reste : c'est son plan de travail.
      expect(find.textContaining('Logements'), findsOneWidget);
    });
  });
}
