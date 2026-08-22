import '../data/models/owner_profile_model.dart';

/// États de l'écran de finalisation d'inscription.
sealed class OwnerProfileState {
  const OwnerProfileState();
}

final class OwnerProfileInitial extends OwnerProfileState {
  const OwnerProfileInitial();
}

/// Chargement du dossier existant, avant affichage du formulaire.
final class OwnerProfileLoading extends OwnerProfileState {
  const OwnerProfileLoading();
}

/// Formulaire prêt. [profile] est nul lorsqu'aucun dossier n'a encore été
/// déposé — cas d'une première inscription.
final class OwnerProfileReady extends OwnerProfileState {
  const OwnerProfileReady(this.profile);
  final OwnerProfileModel? profile;
}

/// Dépôt en cours. État distinct du chargement initial : l'UI doit verrouiller
/// le formulaire, pas le remplacer par un indicateur plein écran.
final class OwnerProfileSubmitting extends OwnerProfileState {
  const OwnerProfileSubmitting();
}

/// Dossier transmis et accepté par le serveur.
final class OwnerProfileSubmitted extends OwnerProfileState {
  const OwnerProfileSubmitted(this.profile);
  final OwnerProfileModel profile;
}

final class OwnerProfileError extends OwnerProfileState {
  const OwnerProfileError(this.message, {this.profile});

  final String message;

  /// Dossier déjà chargé, conservé pour que l'échec d'un dépôt ne vide pas le
  /// formulaire que l'utilisateur vient de remplir.
  final OwnerProfileModel? profile;
}
