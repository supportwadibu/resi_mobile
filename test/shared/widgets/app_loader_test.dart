import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';

void main() {
  group('AppLoader', () {
    testWidgets('charge réellement l’asset Lottie', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppLoader())),
      );
      // Le décodage de l'asset est asynchrone, mais l'animation boucle sans
      // fin : `pumpAndSettle` n'atteindrait jamais le repos. On avance de
      // quelques trames, ce qui suffit à laisser l'erreur survenir.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(LottieBuilder), findsOneWidget);
      // Le repli n'apparaît que si l'asset est absent ou illisible : sa
      // présence signalerait un chemin ou une déclaration pubspec erronés.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('respecte la taille demandée', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppLoader(size: 48))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final box = tester.getSize(find.byType(AppLoader));
      expect(box.width, 48);
      expect(box.height, 48);
    });

    testWidgets('AppLoaderScreen centre le loader', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppLoaderScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
