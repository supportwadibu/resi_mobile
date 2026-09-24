import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/rapport/data/models/report_export_model.dart';

void main() {
  // Le modèle n'a plus de `fromJson` : l'API renvoie désormais le PDF dans
  // le corps de la réponse, c'est le repository qui construit ce modèle
  // après avoir écrit les octets sur le disque. Rien à parser ici — on
  // vérifie seulement que les champs retenus sont bien portés.
  group('ReportExportModel', () {
    test('porte le chemin du fichier écrit localement et son nom', () {
      const model = ReportExportModel(
        filePath: '/tmp/rapport-financial.pdf',
        filename: 'rapport-financier-mars-2026.pdf',
      );

      expect(model.filePath, '/tmp/rapport-financial.pdf');
      expect(model.filename, 'rapport-financier-mars-2026.pdf');
    });
  });
}
