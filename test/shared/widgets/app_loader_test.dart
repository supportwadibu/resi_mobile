import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/theme/app_theme.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/loading_shimmer.dart';

void main() {
  group('AppLoader', () {
    testWidgets('dessine des blocs balayés, jamais un anneau', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: AppLoader()),
        ),
      );

      expect(find.byType(ShimmerEffect), findsOneWidget);
      expect(find.byType(LoadingShimmer), findsNWidgets(3));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('une petite taille donne une barre de cette hauteur', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: Center(child: AppLoader(size: 20))),
        ),
      );

      expect(find.byType(LoadingShimmer), findsOneWidget);
      expect(tester.getSize(find.byType(AppLoader)).height, 20);
    });

    testWidgets('AppLoaderScreen montre le squelette de page', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppLoaderScreen()));

      expect(find.byType(PageSkeleton), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
