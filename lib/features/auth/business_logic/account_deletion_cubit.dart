import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../data/repositories/account_repository.dart';
import 'account_deletion_state.dart';

/// Pilote la suppression du compte : aperçu des obstacles, puis envoi.
///
/// La purge de l'appareil et le retour à la connexion restent à l'écran :
/// ils passent par `AuthService` et le routeur, que le cubit n'a pas à
/// connaître.
class AccountDeletionCubit extends Cubit<AccountDeletionState> {
  AccountDeletionCubit(this._repository)
    : super(const AccountDeletionInitial());

  final AccountRepository _repository;

  Future<void> load() async {
    emit(const AccountDeletionLoading());
    try {
      final preview = await _repository.fetchDeletionPreview();
      if (!isClosed) emit(AccountDeletionReady(preview));
    } on AppFailure catch (f) {
      if (!isClosed) emit(AccountDeletionError(f.userMessage));
    }
  }

  Future<void> delete({String? reason}) async {
    final current = state;
    if (current is! AccountDeletionReady || current.submitting) return;

    emit(AccountDeletionReady(current.preview, submitting: true));
    try {
      await _repository.deleteAccount(reason: reason);
      if (!isClosed) {
        emit(AccountDeletionDone(current.preview.gracePeriodDays));
      }
    } on AppFailure catch (f) {
      // 409 : un obstacle est apparu depuis l'aperçu (un retrait demandé
      // entre-temps…). Le message de l'API le nomme ; l'aperçu est relu pour
      // que la liste affichée le montre aussi.
      if (isClosed) return;
      if (f.statusCode == 409) {
        await load();
        final reloaded = state;
        if (!isClosed && reloaded is AccountDeletionReady) {
          emit(AccountDeletionReady(reloaded.preview, error: f.userMessage));
        }
        return;
      }
      emit(AccountDeletionReady(current.preview, error: f.userMessage));
    }
  }
}
