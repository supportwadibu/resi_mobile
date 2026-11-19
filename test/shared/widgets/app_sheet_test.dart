import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/theme/app_theme.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/confirm_dialog.dart';

/// Petit écran (360 × 640), barre de navigation d'Android de 48 et texte
/// agrandi : le cas où la dernière ligne d'une feuille passait sous la barre.
const _screenHeight = 640.0;
const _navigationBar = 48.0;

void _smallScreenLargeText(WidgetTester tester, double textScale) {
  tester.view.physicalSize = const Size(720, 1280);
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(bottom: _navigationBar * 2);
  tester.view.viewPadding = const FakeViewPadding(bottom: _navigationBar * 2);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _open(WidgetTester tester, WidgetBuilder sheet) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () =>
                  showAppSheet<void>(context: context, builder: sheet),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

/// La feuille « Nouvelle réservation » du propriétaire.
Widget _reservationModes(BuildContext _) => AppSheet(
  title: 'Nouvelle réservation',
  description: 'Le client est-il déjà sur place ?',
  showClose: false,
  padding: const EdgeInsets.only(bottom: 8),
  child: Column(
    children: [
      AppSheetAction(
        icon: Icons.login,
        label: 'Check-in immédiat',
        description: 'Le client entre maintenant',
        onTap: () {},
      ),
      AppSheetAction(
        icon: Icons.event,
        label: 'Réservation future',
        description: 'Séjour prévu à une date à venir',
        onTap: () {},
      ),
    ],
  ),
);

Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.drag(
    find.byType(SingleChildScrollView).last,
    const Offset(0, -3000),
  );
  await tester.pumpAndSettle();
}

void _expectAboveNavigationBar(WidgetTester tester, Finder finder) {
  final bottom = tester.getRect(finder).bottom;
  expect(
    bottom,
    lessThanOrEqualTo(_screenHeight - _navigationBar),
    reason: 'la dernière ligne passe sous la barre de navigation',
  );
}

void main() {
  group('Feuille du bas — contenu entièrement visible', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('texte × $scale : la dernière action reste au-dessus de la '
          'barre de navigation', (tester) async {
        _smallScreenLargeText(tester, scale);
        await _open(tester, _reservationModes);

        // Jusqu'en bas de la feuille : sa toute dernière ligne doit se lire en
        // entier au-dessus de la barre de navigation.
        await _scrollToEnd(tester);
        final last = find.text('Séjour prévu à une date à venir');

        expect(tester.takeException(), isNull);
        _expectAboveNavigationBar(tester, last);
        expect(tester.hitTestOnBinding(tester.getCenter(last)), isNotNull);
      });
    }

    testWidgets('une longue liste défile jusqu’à son dernier élément', (
      tester,
    ) async {
      _smallScreenLargeText(tester, 2.0);
      await _open(
        tester,
        (_) => AppSheet(
          title: 'Choisir un bien',
          showClose: false,
          child: Column(
            children: [
              for (var i = 1; i <= 12; i++)
                AppSheetAction(
                  icon: Icons.home,
                  label: 'Bien $i',
                  onTap: () {},
                ),
            ],
          ),
        ),
      );

      await _scrollToEnd(tester);
      final last = find.text('Bien 12');

      expect(tester.takeException(), isNull);
      _expectAboveNavigationBar(tester, last);
    });

    testWidgets('le pied d’actions reste au-dessus de la barre de navigation', (
      tester,
    ) async {
      _smallScreenLargeText(tester, 2.0);
      await _open(
        tester,
        (_) => AppSheet(
          title: 'Filtres',
          showClose: false,
          footer: AppButton(label: 'Appliquer', expand: true, onPressed: () {}),
          child: const SizedBox(height: 120),
        ),
      );

      expect(tester.takeException(), isNull);
      _expectAboveNavigationBar(tester, find.text('Appliquer'));
    });
  });

  // Déconnexion, suppression : la confirmation s'ouvre en feuille du bas, et
  // non plus en dialogue au centre de l'écran.
  testWidgets('la confirmation s’ouvre en feuille du bas et rend le choix', (
    tester,
  ) async {
    _smallScreenLargeText(tester, 1.5);
    bool? answer;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => answer = await showConfirmDialog(
                  context: context,
                  title: 'Se déconnecter',
                  message: 'Vous devrez vous reconnecter.',
                  confirmLabel: 'Se déconnecter',
                  cancelLabel: 'Annuler',
                  danger: true,
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    _expectAboveNavigationBar(tester, find.text('Annuler'));

    await tester.tap(find.widgetWithText(AppButton, 'Se déconnecter'));
    await tester.pumpAndSettle();
    expect(answer, isTrue);
  });
}
