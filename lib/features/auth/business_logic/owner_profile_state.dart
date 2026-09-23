import '../../gerant/data/models/gerant_account_model.dart';
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

/// Compte du gérant connecté.
///
/// Type distinct et non un `OwnerProfileReady` dont les champs manquants
/// seraient nuls : ce que le gérant n'a pas — pièce d'identité, adresse, ville,
/// statut de validation — n'est pas un dossier incomplet mais une notion qui ne
/// le concerne pas. `OwnerProfileModel` les porte tous en optionnels, et l'y
/// couler laisserait l'écran juger son dossier « à compléter » et lui proposer
/// de déposer une pièce d'identité qu'aucune route n'accepterait de lui.
///
/// La séparation des types est ce qui garantit qu'aucun oubli d'affichage ne
/// puisse lui montrer un bloc propriétaire vide.
final class ManagerProfileReady extends OwnerProfileState {
  const ManagerProfileReady(this.account);

  /// Nom, coordonnées, périmètre et état du compte, servis par
  /// `GET /gerant/profile`. Les coordonnées y sont en lecture seule : seul le
  /// propriétaire qui a ouvert le compte les modifie.
  final GerantAccountModel account;
}

final class OwnerProfileError extends OwnerProfileState {
  const OwnerProfileError(this.message, {this.profile});

  final String message;

  /// Dossier déjà chargé, conservé pour que l'échec d'un dépôt ne vide pas le
  /// formulaire que l'utilisateur vient de remplir.
  final OwnerProfileModel? profile;
}
