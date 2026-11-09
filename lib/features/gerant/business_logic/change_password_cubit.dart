import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/gerant_repository.dart';

/// États du changement de mot de passe du gérant.
sealed class ChangePasswordState {
  const ChangePasswordState();
}

final class ChangePasswordIdle extends ChangePasswordState {
  const ChangePasswordIdle({this.error});

  /// Échec du dernier envoi — ancien mot de passe faux, réseau absent.
  final String? error;
}

final class ChangePasswordSubmitting extends ChangePasswordState {
  const ChangePasswordSubmitting();
}

final class ChangePasswordDone extends ChangePasswordState {
  const ChangePasswordDone();
}

/// Changement du mot de passe par le gérant lui-même, l'ancien exigé.
///
/// Le propriétaire fixe le mot de passe initial à la création du compte ;
/// le gérant le remplace ici par un mot de passe que lui seul connaît.
class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit(this._repository) : super(const ChangePasswordIdle());

  final GerantRepository _repository;

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state is ChangePasswordSubmitting) return;
    emit(const ChangePasswordSubmitting());
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!isClosed) emit(const ChangePasswordDone());
    } on AppFailure catch (f) {
      if (!isClosed) emit(ChangePasswordIdle(error: f.userMessage));
    }
  }
}
