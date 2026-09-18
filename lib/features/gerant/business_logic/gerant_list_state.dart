import '../data/models/gerant_account_model.dart';

/// États de la liste des gérants.
sealed class GerantListState {
  const GerantListState();
}

final class GerantListInitial extends GerantListState {
  const GerantListInitial();
}

final class GerantListLoading extends GerantListState {
  const GerantListLoading();
}

final class GerantListLoaded extends GerantListState {
  const GerantListLoaded(this.items);

  final List<GerantAccountModel> items;
}

final class GerantListError extends GerantListState {
  const GerantListError(this.message);

  final String message;
}
