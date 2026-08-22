import '../data/models/stats_model.dart';

sealed class StatsState { const StatsState(); }

final class StatsInitial extends StatsState { const StatsInitial(); }
final class StatsLoading extends StatsState { const StatsLoading(); }
final class StatsLoaded  extends StatsState {
  const StatsLoaded(this.items);
  final List<StatsModel> items;
}
final class StatsError extends StatsState {
  const StatsError(this.message);
  final String message;
}
