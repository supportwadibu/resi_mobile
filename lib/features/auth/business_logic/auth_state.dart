import '../data/models/auth_model.dart';

sealed class AuthState {
  const AuthState();
}

/// Le compte est créé et le code de vérification envoyé, mais l'inscription
/// n'est pas terminée : aucun token n'a encore été délivré. L'UI doit conduire
/// l'utilisateur vers la saisie du code.
final class AuthOtpSent extends AuthState {
  const AuthOtpSent({
    required this.channel,
    required this.target,
    this.devOtpCode,
  });

  /// `email` ou `phone` — à renvoyer tel quel lors de la vérification.
  final String channel;

  /// Destination du code, à afficher pour confirmation.
  final String target;

  /// Code en clair fourni par l'API hors production, pour tester sans accès
  /// à la boîte mail ni aux SMS. Nul en production.
  final String? devOtpCode;
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthSuccess extends AuthState {
  const AuthSuccess(this.auth);
  final AuthModel auth;
}

final class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}

/// L'utilisateur a fermé la feuille Google sans choisir de compte.
/// État distinct de [AuthError] : rien n'a échoué, l'UI ne doit rien signaler.
final class AuthCancelled extends AuthState {
  const AuthCancelled();
}

final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}
