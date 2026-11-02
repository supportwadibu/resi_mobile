import '../data/models/property_model.dart';

/// États de la modification d'une annonce.
sealed class EditPropertyState {
  const EditPropertyState();
}

final class EditPropertyIdle extends EditPropertyState {
  const EditPropertyIdle();
}

/// Envoi des nouvelles photos, préalable à l'enregistrement.
///
/// Étape distincte de [EditPropertySubmitting] : elle peut durer sur un réseau
/// lent, et l'utilisateur doit savoir que quelque chose progresse plutôt que
/// de croire l'application figée.
final class EditPropertyUploadingImages extends EditPropertyState {
  const EditPropertyUploadingImages({required this.total});

  /// Nombre de photos nouvellement ajoutées — celles déjà hébergées ne sont
  /// pas renvoyées.
  final int total;
}

final class EditPropertySubmitting extends EditPropertyState {
  const EditPropertySubmitting();
}

final class EditPropertySuccess extends EditPropertyState {
  const EditPropertySuccess(this.property, {this.unchanged = false});

  /// Fiche telle que le serveur l'a enregistrée.
  final PropertyModel property;

  /// Aucun écart n'a été détecté : rien n'a été envoyé.
  ///
  /// L'écran le signale autrement qu'un enregistrement réel — annoncer une
  /// modification qui n'a pas eu lieu ferait douter des suivantes.
  final bool unchanged;
}

final class EditPropertyFailure extends EditPropertyState {
  const EditPropertyFailure(this.message, {this.uploadedImages});

  final String message;

  /// Photos déposées avant l'échec.
  ///
  /// Conservées pour qu'une nouvelle tentative ne les renvoie pas : elles sont
  /// hébergées, seul l'enregistrement a échoué.
  final List<String>? uploadedImages;
}
