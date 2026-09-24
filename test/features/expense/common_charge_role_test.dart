import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/session/session_role.dart';
import 'package:resi_africa/features/expense/business_logic/add_expense_cubit.dart';
import 'package:resi_africa/features/expense/business_logic/add_expense_state.dart';
import 'package:resi_africa/features/expense/presentation/screens/add_expense_screen.dart';
import 'package:resi_africa/features/property/business_logic/property_cubit.dart';
import 'package:resi_africa/features/property/business_logic/property_state.dart';
import 'package:resi_africa/features/residence/business_logic/residence_cubit.dart';
import 'package:resi_africa/features/residence/business_logic/residence_state.dart';

import '../../support/session_role_fixture.dart';

/// `POST /gerant/expenses` exige un `property_id` et répond 422
/// `property_required` sans lui : la charge commune de résidence est fermée au
/// gérant côté serveur. L'écran la lui proposait quand même, et le message du
/// refus se perdait.
///
/// L'écran réel est monté : c'est son câblage qui est en cause.
class _FakePropertyCubit extends Cubit<PropertyState> implements PropertyCubit {
  _FakePropertyCubit() : super(const PropertyLoaded([]));

  @override
  Future<void> load() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeResidenceCubit extends Cubit<ResidenceState>
    implements ResidenceCubit {
  _FakeResidenceCubit() : super(const ResidenceLoaded([]));

  @override
  Future<void> load() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAddExpenseCubit extends Cubit<AddExpenseState>
    implements AddExpenseCubit {
  _FakeAddExpenseCubit() : super(const AddExpenseIdle());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, String role) async {
  sl.registerSingleton<SessionRole>(sessionRoleFixture(role));
  sl.registerFactory<PropertyCubit>(_FakePropertyCubit.new);
  sl.registerFactory<ResidenceCubit>(_FakeResidenceCubit.new);
  sl.registerFactory<AddExpenseCubit>(_FakeAddExpenseCubit.new);

  await tester.pumpWidget(const MaterialApp(home: AddExpenseScreen()));
  await tester.pump();
}

void main() {
  // L'écran met la date en forme avec la locale `fr`.
  setUpAll(() => initializeDateFormatting('fr'));

  setUp(() => GetIt.instance.reset());
  tearDown(() => GetIt.instance.reset());

  group('Saisie d’une dépense — charge commune de résidence', () {
    testWidgets('le propriétaire choisit entre logement et partie commune', (
      tester,
    ) async {
      await _pump(tester, 'proprio');

      expect(find.text('Type de dépense'), findsOneWidget);
      expect(find.text('Partie commune'), findsOneWidget);
      expect(find.text('Un logement'), findsOneWidget);
    });

    testWidgets('le gérant ne voit pas « Partie commune »', (tester) async {
      await _pump(tester, 'gerant');

      expect(find.text('Partie commune'), findsNothing);
    });

    testWidgets('le gérant ne voit plus le choix du tout', (tester) async {
      // Un seul type restant, le sélecteur n'a plus rien à départager : il
      // disparaît avec l'option, plutôt que de laisser un choix sans choix.
      await _pump(tester, 'gerant');

      expect(find.text('Type de dépense'), findsNothing);
      expect(find.text('Un logement'), findsNothing);
    });

    testWidgets('le gérant garde la saisie sur un logement', (tester) async {
      await _pump(tester, 'gerant');

      // Le sélecteur de cible reste, sur sa seule forme permise.
      expect(find.text('Logement concerné'), findsOneWidget);
      expect(find.text('Résidence concernée'), findsNothing);
      // Et le reste du formulaire est intact.
      expect(find.text('Catégorie'), findsOneWidget);
    });
  });
}
