import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/theme/app_theme.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';

void main() {
  group('AppLoader', () {
    testWidgets('dessine un anneau à la couleur du texte', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: AppLoader()),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      // Le texte, et non une teinte de marque : l'anneau reste lisible dans
      // les deux modes.
      expect(indicator.color, ResiTokens.light.foreground);
    });

    testWidgets('suit le mode sombre', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: AppLoader()),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.color, ResiTokens.dark.foreground);
    });

    testWidgets('respecte la taille demandée', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppLoader(size: 48))),
      );

      final box = tester.getSize(find.byType(AppLoader));
      expect(box.width, 48);
      expect(box.height, 48);
    });

    testWidgets('AppLoaderScreen centre le loader', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppLoaderScreen()));

      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
