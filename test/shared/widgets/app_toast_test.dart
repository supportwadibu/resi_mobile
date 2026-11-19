import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/theme/app_theme.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';

/// Écran dont l'état porte un message d'échec, comme une feuille d'envoi.
class _Host extends StatefulWidget {
  const _Host();
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String? message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(
          onPressed: () => setState(() => message = 'Retrait refusé'),
          child: const Text('échouer'),
        ),
        TextButton(
          onPressed: () => setState(() => message = null),
          child: const Text('réessayer'),
        ),
        if (message != null) AppToastOnMessage(message),
      ],
    ),
  );
}

void main() {
  testWidgets('un échec porté par l’état s’annonce en toast, puis s’efface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const _Host()),
    );

    await tester.tap(find.text('échouer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Retrait refusé'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Retrait refusé'), findsNothing);
  });

  testWidgets('le même échec après une nouvelle tentative se réannonce', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light(), home: const _Host()),
    );

    await tester.tap(find.text('échouer'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Retrait refusé'), findsNothing);

    await tester.tap(find.text('réessayer'));
    await tester.pump();
    await tester.tap(find.text('échouer'));
    await tester.pump();
    // Le toast s'insère après l'image ; son entrée part à la suivante.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Retrait refusé'), findsOneWidget);

    // Un toucher referme le toast sans attendre.
    await tester.tap(find.text('Retrait refusé'));
    await tester.pumpAndSettle();
    expect(find.text('Retrait refusé'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });
}
