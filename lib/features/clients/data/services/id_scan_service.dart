import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'mrz_parser.dart';

/// Lecture d'une photo de pièce d'identité, sur l'appareil.
///
/// Reconnaissance ML Kit locale : gratuite, et disponible hors ligne — la
/// saisie au comptoir doit l'être aussi. Seule la bande MRZ est exploitée
/// (`MrzParser`) : le reste du texte varie d'une pièce à l'autre.
class IdScanService {
  const IdScanService();

  /// `null` si aucune MRZ n'est reconnue : le propriétaire saisit alors à la
  /// main, et rien ne bloque l'enregistrement.
  Future<MrzResult?> scan(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return MrzParser.parse(recognized.text);
    } catch (_) {
      // Moteur indisponible sur l'appareil, image illisible : la lecture est
      // un confort, son échec vaut « rien de lu ».
      return null;
    } finally {
      await recognizer.close();
    }
  }
}
