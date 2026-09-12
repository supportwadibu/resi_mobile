import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/models/residence_model.dart';
import '../data/repositories/residence_repository.dart';
import 'residence_state.dart';

class ResidenceCubit extends Cubit<ResidenceState> {
  ResidenceCubit(this._repository) : super(const ResidenceInitial());

  final ResidenceRepository _repository;

  Future<void> load() async {
    emit(const ResidenceLoading());
    try {
      final items = await _repository.getAllResidences();
      if (!isClosed) emit(ResidenceLoaded(items));
    } on AppFailure catch (f) {
      if (!isClosed) emit(ResidenceError(f.userMessage));
    }
  }

  /// Crée une résidence et l'insère en tête de liste.
  ///
  /// La liste est mise à jour sur place plutôt que rechargée : le tri est par
  /// date de création décroissante, la nouvelle venue est donc en tête, et un
  /// rechargement complet ferait clignoter l'écran pour rien.
  ///
  /// Retourne `null` en cas d'échec, l'appelant ayant besoin de savoir s'il
  /// peut fermer son formulaire.
  Future<ResidenceModel?> create(CreateResidencePayload payload) async {
    final current = state;
    try {
      final created = await _repository.createResidence(payload);
      if (isClosed) return created;

      if (current is ResidenceLoaded) {
        emit(ResidenceLoaded([created, ...current.items]));
      } else {
        emit(ResidenceLoaded([created]));
      }

      return created;
    } on AppFailure catch (f) {
      if (!isClosed) emit(ResidenceError(f.userMessage));
      return null;
    }
  }

  Future<ResidenceModel?> update(String id, UpdateResidencePayload payload) async {
    if (payload.isEmpty) return null;

    final current = state;
    try {
      final updated = await _repository.updateResidence(id, payload);
      if (isClosed) return updated;

      if (current is ResidenceLoaded) {
        emit(
          ResidenceLoaded([
            for (final item in current.items)
              if (item.id == id) updated else item,
          ]),
        );
      }

      return updated;
    } on AppFailure catch (f) {
      if (!isClosed) emit(ResidenceError(f.userMessage));
      return null;
    }
  }

  /// Supprime une résidence.
  ///
  /// Retourne le message d'échec plutôt que de basculer l'écran en erreur : un
  /// refus pour cause de logements rattachés (409) doit s'afficher sans faire
  /// disparaître la liste, que le propriétaire consulte justement pour les
  /// détacher.
  Future<String?> delete(String id) async {
    final current = state;
    try {
      await _repository.deleteResidence(id);
      if (isClosed) return null;

      if (current is ResidenceLoaded) {
        emit(
          ResidenceLoaded([
            for (final item in current.items)
              if (item.id != id) item,
          ]),
        );
      }

      return null;
    } on AppFailure catch (f) {
      return f.userMessage;
    }
  }
}
