import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/failures.dart';
import '../data/models/feedback_model.dart';
import '../data/repositories/feedback_repository.dart';
import '../data/services/feedback_context_service.dart';
import 'feedback_state.dart';

/// Pilote l'envoi d'un avis sur l'application.
class FeedbackCubit extends Cubit<FeedbackState> {
  FeedbackCubit(this._repository, this._contextService)
    : super(const FeedbackInitial());

  final FeedbackRepository _repository;
  final FeedbackContextService _contextService;

  /// Envoie l'avis saisi.
  ///
  /// Le contexte technique est assemblé ici et non dans le formulaire : l'écran
  /// n'a pas à connaître la version de l'application pour afficher deux champs
  /// de texte.
  Future<void> submit({
    required FeedbackType type,
    required String title,
    required String message,
  }) async {
    // Un second appui pendant l'envoi produirait un doublon que le serveur
    // refuserait en 429 — et l'utilisateur verrait une erreur pour un avis
    // pourtant bien parti.
    if (state is FeedbackSubmitting) return;

    emit(const FeedbackSubmitting());

    try {
      final context = await _contextService.collect();

      final feedback = await _repository.create(
        CreateFeedbackPayload(
          type: type,
          title: title.trim(),
          message: message.trim(),
          context: context,
        ),
      );

      if (!isClosed) emit(FeedbackSuccess(feedback));
    } on AppFailure catch (f) {
      if (!isClosed) emit(FeedbackError(f.userMessage));
    }
  }
}
