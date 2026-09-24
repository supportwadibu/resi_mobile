import '../data/models/feedback_model.dart';

/// États de l'envoi d'un avis sur l'application.
sealed class FeedbackState {
  const FeedbackState();
}

final class FeedbackInitial extends FeedbackState {
  const FeedbackInitial();
}

final class FeedbackSubmitting extends FeedbackState {
  const FeedbackSubmitting();
}

final class FeedbackSuccess extends FeedbackState {
  const FeedbackSuccess(this.feedback);

  final FeedbackModel feedback;
}

final class FeedbackError extends FeedbackState {
  const FeedbackError(this.message);

  final String message;
}
