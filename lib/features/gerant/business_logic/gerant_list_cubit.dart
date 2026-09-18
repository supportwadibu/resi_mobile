import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/models/gerant_account_model.dart';
import '../data/repositories/gerant_admin_repository.dart';
import 'gerant_list_state.dart';

export 'gerant_list_state.dart';

/// Gérants du propriétaire : ouverture d'un compte, suspension, réactivation.
class GerantListCubit extends Cubit<GerantListState> {
  GerantListCubit(this._repository) : super(const GerantListInitial());

  final GerantAdminRepository _repository;

  Future<void> load() async {
    emit(const GerantListLoading());
    try {
      final items = await _repository.list();
      if (!isClosed) emit(GerantListLoaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit(GerantListError(f.userMessage));
    }
  }

  /// Ouvre un compte gérant et l'insère en tête de liste.
  ///
  /// Rend le gérant créé, ou `null` si la création a échoué — l'appelant a
  /// besoin de savoir s'il peut fermer son formulaire. Le message d'échec est
  /// porté par [lastError] plutôt que par un état d'erreur : basculer l'écran
  /// ferait disparaître la saisie qu'il faut justement corriger.
  Future<GerantAccountModel?> create(CreateGerantPayload payload) async {
    final current = state;
    try {
      final created = await _repository.create(payload);
      if (isClosed) return created;

      emit(
        GerantListLoaded([
          created,
          if (current is GerantListLoaded) ...current.items,
        ]),
      );
      return created;
    } on AppFailure catch (f) {
      lastError = f.userMessage;
      return null;
    }
  }

  /// Message du dernier échec de création ou de statut, non affiché par l'état.
  String? lastError;

  /// Suspend ou réactive un gérant, et met la liste à jour sur place.
  ///
  /// Rend le message d'échec plutôt que de basculer l'écran en erreur : un
  /// refus ne doit pas faire disparaître la liste que le propriétaire consulte.
  Future<String?> setStatus(String id, {required bool isActive}) async {
    final current = state;
    try {
      final updated = await _repository.setStatus(id, isActive: isActive);
      if (isClosed) return null;

      if (current is GerantListLoaded) {
        emit(
          GerantListLoaded([
            for (final item in current.items)
              if (item.id == id) updated else item,
          ]),
        );
      }
      return null;
    } on AppFailure catch (f) {
      return f.userMessage;
    }
  }
}
