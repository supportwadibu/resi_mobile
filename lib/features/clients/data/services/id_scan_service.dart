import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'id_card_reading.dart';

/// Lecture d'une photo de pièce d'identité, sur l'appareil.
///
/// Reconnaissance ML Kit locale : gratuite, et disponible hors ligne — la
/// saisie au comptoir doit l'être aussi. ML Kit ne fait qu'**analyser** une
/// image : la prise de vue revient à `image_picker`, appareil photo ou
/// galerie, et ce service lit ce qu'on lui donne.
///
/// Deux lectures du même texte, combinées par `IdCardReading.fromText` : la
/// bande MRZ, normalisée et vérifiée, et les libellés imprimés, qui portent ce
/// que la MRZ n'a pas — lieu de naissance, délivrance, domicile.
class IdScanService {
  const IdScanService();

  /// `null` si rien n'est lu : le propriétaire saisit alors à la main, et rien
  /// ne bloque l'enregistrement.
  Future<IdCardReading?> scan(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      return IdCardReading.fromText(recognized.text);
    } catch (_) {
      // Moteur indisponible sur l'appareil, image illisible : la lecture est
      // un confort, son échec vaut « rien de lu ».
      return null;
    } finally {
      await recognizer.close();
    }
  }
}
