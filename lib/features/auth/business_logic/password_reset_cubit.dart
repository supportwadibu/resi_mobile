import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/models/auth_model.dart';
import '../data/models/password_reset_model.dart';
import '../data/services/auth_service.dart';

/// États du mot de passe oublié : le numéro, puis le code et le nouveau mot
/// de passe.
sealed class PasswordResetState {
  const PasswordResetState();
}

/// Saisie du numéro. [error] porte l'échec d'une demande de code.
final class PasswordResetAskIdentifier extends PasswordResetState {
  const PasswordResetAskIdentifier({this.sending = false, this.error});
  final bool sending;
  final String? error;
}

/// Code envoyé : saisie du code et du nouveau mot de passe.
final class PasswordResetAskCode extends PasswordResetState {
  const PasswordResetAskCode(
    this.request, {
    this.submitting = false,
    this.resending = false,
    this.error,
  });

  final PasswordResetRequest request;
  final bool submitting;
  final bool resending;
  final String? error;

  PasswordResetAskCode copyWith({
    PasswordResetRequest? request,
    bool submitting = false,
    bool resending = false,
    String? error,
  }) => PasswordResetAskCode(
    request ?? this.request,
    submitting: submitting,
    resending: resending,
    error: error,
  );
}

/// Mot de passe changé, session ouverte.
final class PasswordResetDone extends PasswordResetState {
  const PasswordResetDone(this.auth);
  final AuthModel auth;
}

/// Mot de passe oublié.
///
/// Les erreurs restent dans l'étape où elles surviennent : un code faux ne
/// doit pas renvoyer à la saisie du numéro, et faire tout ressaisir.
class PasswordResetCubit extends Cubit<PasswordResetState> {
  PasswordResetCubit(this._service) : super(const PasswordResetAskIdentifier());

  final AuthService _service;

  Future<void> requestCode(String identifier) async {
    emit(const PasswordResetAskIdentifier(sending: true));
    try {
      final request = await _service.requestPasswordReset(identifier);
      if (!isClosed) emit(PasswordResetAskCode(request));
    } on AppFailure catch (f) {
      if (!isClosed) emit(PasswordResetAskIdentifier(error: f.userMessage));
    }
  }

  /// Nouveau code : il remplace le précédent, côté serveur.
  Future<void> resendCode() async {
    final current = state;
    if (current is! PasswordResetAskCode || current.resending) return;
    emit(current.copyWith(resending: true));
    try {
      final request = await _service.requestPasswordReset(
        current.request.identifier,
      );
      if (!isClosed) emit(current.copyWith(request: request));
    } on AppFailure catch (f) {
      if (!isClosed) emit(current.copyWith(error: f.userMessage));
    }
  }

  Future<void> reset({required String code, required String password}) async {
    final current = state;
    if (current is! PasswordResetAskCode || current.submitting) return;
    emit(current.copyWith(submitting: true));
    try {
      final auth = await _service.resetPassword(
        identifier: current.request.identifier,
        code: code,
        password: password,
      );
      if (!isClosed) emit(PasswordResetDone(auth));
    } on AppFailure catch (f) {
      if (!isClosed) emit(current.copyWith(error: f.userMessage));
    }
  }

  /// Retour à la saisie du numéro, pour corriger une faute de frappe.
  void changeIdentifier() => emit(const PasswordResetAskIdentifier());
}
