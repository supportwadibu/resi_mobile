import '../data/models/residence_model.dart';

/// États de la liste des résidences.
sealed class ResidenceState {
  const ResidenceState();
}

final class ResidenceInitial extends ResidenceState {
  const ResidenceInitial();
}

final class ResidenceLoading extends ResidenceState {
  const ResidenceLoading();
}

final class ResidenceLoaded extends ResidenceState {
  const ResidenceLoaded(this.items);

  final List<ResidenceModel> items;
}

final class ResidenceError extends ResidenceState {
  const ResidenceError(this.message);

  final String message;
}
