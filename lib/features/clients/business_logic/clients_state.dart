import '../data/models/client_filter_model.dart';
import '../data/models/client_model.dart';

sealed class ClientsState {
  const ClientsState();
}

final class ClientsInitial extends ClientsState {
  const ClientsInitial();
}

final class ClientsLoading extends ClientsState {
  const ClientsLoading();
}

final class ClientsLoaded extends ClientsState {
  const ClientsLoaded({
    required this.items,
    this.query = '',
    this.filter = ClientFilter.all,
    this.isLoadingMore = false,
    this.hasMore = false,
  });

  final List<ClientModel> items;
  final String query;
  final ClientFilter filter;

  /// Une page suivante est en cours de chargement : la liste reste affichée,
  /// un indicateur s'ajoute en pied.
  final bool isLoadingMore;
  final bool hasMore;

  ClientsLoaded copyWith({
    List<ClientModel>? items,
    String? query,
    ClientFilter? filter,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return ClientsLoaded(
      items: items ?? this.items,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final class ClientsError extends ClientsState {
  const ClientsError(this.message);
  final String message;
}
