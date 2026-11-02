import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/reservation/presentation/widgets/sync_status_banner.dart';

void main() {
  group('libelle du bandeau de synchronisation', () {
    // Les libelles affiches sont accentues, comme tout le texte du depot : les
    // attentes le sont aussi, sinon elles ne compareraient rien.

    test('un rejet se dit hors perimetre, pas periode prise', () {
      // Les deux refus ne s'arbitrent pas de la meme facon : confondre les
      // libelles laisserait le gerant attendre une decision qui ne viendra pas.
      final label = SyncStatusBanner.label(0, 0, 1);

      expect(label, contains('périmètre'));
      expect(label, isNot(contains('période')));
    });

    test('le rejet prime sur le conflit et sur l’attente', () {
      // Il est definitif, la ou un conflit attend encore une decision.
      expect(SyncStatusBanner.label(3, 2, 1), contains('périmètre'));
    });

    test('le conflit prime sur l’attente', () {
      final label = SyncStatusBanner.label(3, 1, 0);

      expect(label, contains('période'));
      expect(label, isNot(contains('attente')));
    });

    test('sans refus, le bandeau parle d’attente d’envoi', () {
      expect(SyncStatusBanner.label(2, 0, 0), contains('attente'));
    });

    test('le singulier et le pluriel different', () {
      expect(
        SyncStatusBanner.label(0, 0, 1),
        isNot(SyncStatusBanner.label(0, 0, 2)),
      );
      expect(SyncStatusBanner.label(0, 0, 2), contains('2'));
    });
  });
}
