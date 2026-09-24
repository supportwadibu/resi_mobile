/// Rapport reçu du serveur et écrit localement : plus de lien à consommer,
/// l'API renvoie désormais le PDF dans le corps de la réponse (Cloudinary
/// exigeait une authentification par jeton que l'offre gratuite ne fournit
/// pas pour les documents privés — 401 en production).
///
/// [filePath] pointe vers le fichier temporaire écrit par le repository ;
/// contrairement à l'ancienne URL signée, il ne périme pas.
class ReportExportModel {
  const ReportExportModel({
    required this.filePath,
    required this.filename,
  });

  final String filePath;
  final String filename;
}
