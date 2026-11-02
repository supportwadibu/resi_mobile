import '../data/models/booking_stats_model.dart';
import '../data/models/reservation_model.dart';

sealed class ReservationState {
  const ReservationState();
}

final class ReservationInitial extends ReservationState {
  const ReservationInitial();
}

final class ReservationLoading extends ReservationState {
  const ReservationLoading({this.stats});

  /// Chiffres déjà obtenus, gardés pendant un changement de filtre : ils
  /// portent sur le mois entier et ne dépendent pas du statut choisi.
  final BookingStatsModel? stats;
}

final class ReservationLoaded extends ReservationState {
  const ReservationLoaded(
    this.items, {
    this.stats,
    this.query = '',
    this.total = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  /// Réservations chargées pour le statut choisi — pages cumulées, avant la
  /// recherche.
  final List<ReservationModel> items;

  /// Nombre de réservations côté serveur pour le statut choisi, pages non
  /// chargées comprises.
  final int total;

  /// Il reste au moins une page à demander.
  final bool hasMore;

  /// Page suivante en cours de chargement : la liste reste affichée.
  final bool isLoadingMore;

  /// Échec de la dernière page demandée. Les pages déjà chargées restent
  /// affichées : un réseau qui flanche ne doit pas vider la liste.
  final String? loadMoreError;

  ReservationLoaded copyWith({
    List<ReservationModel>? items,
    String? query,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearLoadMoreError = false,
  }) => ReservationLoaded(
    items ?? this.items,
    stats: stats,
    query: query ?? this.query,
    total: total ?? this.total,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreError: clearLoadMoreError
        ? null
        : (loadMoreError ?? this.loadMoreError),
  );

  /// Chiffres du tableau de bord, `null` tant qu'ils n'ont pas été obtenus.
  ///
  /// Portés par le même état que la liste : les compteurs dérivent des mêmes
  /// réservations, et les servir depuis un état séparé exposerait à afficher
  /// « 12 en cours » au-dessus d'une liste qui en montre trois.
  ///
  /// Reste `null` quand seul cet appel échoue : mieux vaut la liste sans ses
  /// chiffres qu'un écran vide.
  final BookingStatsModel? stats;

  /// Recherche client saisie, appliquée localement à [items].
  final String query;

  /// Réservations affichées : celles dont le client répond à [query].
  ///
  /// Nom et téléphone viennent de l'instantané figé à la réservation — c'est
  /// le nom sous lequel le séjour a été vendu. Une réservation en ligne ne
  /// porte pas d'instantané client : elle sort de la liste dès qu'une
  /// recherche est saisie.
  List<ReservationModel> get visibleItems {
    final needle = normalizeSearch(query);
    if (needle.isEmpty) return items;

    final digits = needle.replaceAll(RegExp(r'\D'), '');
    return items
        .where((r) {
          final client = r.client;
          if (client == null) return false;
          if (normalizeSearch(client.fullName).contains(needle)) return true;
          // Le téléphone se compare chiffres seuls : « 07 01 02 » et « 070102 »
          // désignent le même numéro.
          return digits.isNotEmpty &&
              client.phone.replaceAll(RegExp(r'\D'), '').contains(digits);
        })
        .toList(growable: false);
  }
}

final class ReservationError extends ReservationState {
  const ReservationError(this.message);
  final String message;
}

/// Minuscules, sans accents ni espaces superflus : « Kouamé » se trouve en
/// tapant « kouame », ce que fait un clavier sans accents.
String normalizeSearch(String value) {
  const accents = 'àáâãäçèéêëìíîïñòóôõöùúûü';
  const plain = 'aaaaaceeeeiiiinooooouuuu';

  final buffer = StringBuffer();
  for (final char in value.trim().toLowerCase().split('')) {
    final index = accents.indexOf(char);
    buffer.write(index == -1 ? char : plain[index]);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
}
