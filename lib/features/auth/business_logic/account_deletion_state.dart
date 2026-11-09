import '../data/models/account_deletion_model.dart';

/// États de l'écran de suppression du compte.
sealed class AccountDeletionState {
  const AccountDeletionState();
}

final class AccountDeletionInitial extends AccountDeletionState {
  const AccountDeletionInitial();
}

final class AccountDeletionLoading extends AccountDeletionState {
  const AccountDeletionLoading();
}

/// Aperçu chargé. [submitting] verrouille l'écran pendant l'envoi sans
/// effacer ce que l'utilisateur lit ; [error] porte l'échec d'un envoi, que
/// l'écran affiche sans perdre l'aperçu.
final class AccountDeletionReady extends AccountDeletionState {
  const AccountDeletionReady(
    this.preview, {
    this.submitting = false,
    this.error,
  });

  final AccountDeletionPreview preview;
  final bool submitting;
  final String? error;
}

/// Compte fermé côté serveur : reste à purger l'appareil.
final class AccountDeletionDone extends AccountDeletionState {
  const AccountDeletionDone(this.gracePeriodDays);
  final int gracePeriodDays;
}

/// Aperçu indisponible : réseau, ou compte qui ne peut pas se supprimer
/// lui-même.
final class AccountDeletionError extends AccountDeletionState {
  const AccountDeletionError(this.message);
  final String message;
}
