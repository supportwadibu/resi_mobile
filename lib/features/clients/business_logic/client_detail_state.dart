import '../data/models/client_model.dart';
import '../data/models/client_reservation_model.dart';

sealed class ClientDetailState {
  const ClientDetailState();
}

final class ClientDetailInitial extends ClientDetailState {
  const ClientDetailInitial();
}

final class ClientDetailLoading extends ClientDetailState {
  const ClientDetailLoading();
}

final class ClientDetailLoaded extends ClientDetailState {
  const ClientDetailLoaded({
    required this.client,
    this.reservations = const [],
    this.isHistoryLoading = false,
    this.historyError,
    this.isSaving = false,
  });

  final ClientModel client;
  final List<ClientReservationModel> reservations;

  /// L'historique se charge après la fiche : celle-ci s'affiche tout de suite,
  /// la liste des séjours arrive ensuite.
  final bool isHistoryLoading;

  /// L'historique a échoué alors que la fiche est lisible.
  ///
  /// Porté à part d'un état d'erreur global : perdre la liste des séjours ne
  /// doit pas masquer les coordonnées du client, qui sont ce dont le
  /// propriétaire a besoin pour l'appeler.
  final String? historyError;

  /// Une modification est en cours d'envoi.
  final bool isSaving;

  ClientDetailLoaded copyWith({
    ClientModel? client,
    List<ClientReservationModel>? reservations,
    bool? isHistoryLoading,
    String? historyError,
    bool clearHistoryError = false,
    bool? isSaving,
  }) {
    return ClientDetailLoaded(
      client: client ?? this.client,
      reservations: reservations ?? this.reservations,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
      historyError: clearHistoryError
          ? null
          : (historyError ?? this.historyError),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

final class ClientDetailError extends ClientDetailState {
  const ClientDetailError(this.message);
  final String message;
}
