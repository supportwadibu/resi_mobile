import '../data/models/home_model.dart';

sealed class HomeState { const HomeState(); }

final class HomeInitial extends HomeState { const HomeInitial(); }
final class HomeLoading extends HomeState { const HomeLoading(); }
final class HomeLoaded  extends HomeState {
  const HomeLoaded(this.items);
  final List<HomeModel> items;
}
final class HomeError extends HomeState {
  const HomeError(this.message);
  final String message;
}
