import '../data/models/property_model.dart';

/// États du dépôt d'une annonce.
sealed class CreatePropertyState {
  const CreatePropertyState();
}

final class CreatePropertyIdle extends CreatePropertyState {
  const CreatePropertyIdle();
}

/// Envoi des photos, préalable à la création.
///
/// Étape distincte de [CreatePropertySubmitting] : elle peut durer sur un
/// réseau lent, et l'utilisateur doit savoir que quelque chose progresse
/// plutôt que de croire l'application figée.
final class CreatePropertyUploadingImages extends CreatePropertyState {
  const CreatePropertyUploadingImages({required this.total});

  final int total;
}

final class CreatePropertySubmitting extends CreatePropertyState {
  const CreatePropertySubmitting();
}

final class CreatePropertySuccess extends CreatePropertyState {
  const CreatePropertySuccess(this.property);

  final PropertyModel property;
}

final class CreatePropertyFailure extends CreatePropertyState {
  const CreatePropertyFailure(this.message, {this.uploadedImages});

  final String message;

  /// Photos déjà déposées avant l'échec.
  ///
  /// Conservées pour qu'une nouvelle tentative ne les renvoie pas : elles sont
  /// hébergées, seule la création a échoué.
  final List<String>? uploadedImages;
}
