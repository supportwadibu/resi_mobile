import '../data/models/rapport_model.dart';

sealed class RapportState { const RapportState(); }

final class RapportInitial extends RapportState { const RapportInitial(); }
final class RapportLoading extends RapportState { const RapportLoading(); }
final class RapportLoaded  extends RapportState {
  const RapportLoaded(this.items);
  final List<RapportModel> items;
}
final class RapportError extends RapportState {
  const RapportError(this.message);
  final String message;
}
