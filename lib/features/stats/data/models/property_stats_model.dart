/// État instantané du parc, servi par `/proprio/properties/stats`.
///
/// Distinct du relevé financier : ces compteurs n'ont pas de période, ils
/// décrivent le parc tel qu'il est au moment de l'appel.
class PropertyStatsModel {
  const PropertyStatsModel({
    required this.total,
    required this.published,
    required this.rented,
    required this.draft,
    required this.totalViews,
  });

  /// Toutes les unités du propriétaire, brouillons compris.
  final int total;

  /// Unités publiées, donc offertes à la location — louées ou non.
  final int published;

  /// Unités actuellement occupées.
  final int rented;

  final int draft;
  final int totalViews;

  /// Unités publiées et libres à la location.
  ///
  /// Calculé plutôt que servi : l'API expose `published` et `rented`, et une
  /// soustraction ici évite d'ajouter un champ dont les deux termes suffisent.
  /// Borné à zéro, un décompte négatif n'ayant aucun sens à l'affichage.
  int get available => published - rented < 0 ? 0 : published - rented;

  factory PropertyStatsModel.fromJson(Map<String, dynamic> json) {
    return PropertyStatsModel(
      total: (json['total'] as num?)?.toInt() ?? 0,
      published: (json['published'] as num?)?.toInt() ?? 0,
      rented: (json['rented'] as num?)?.toInt() ?? 0,
      draft: (json['draft'] as num?)?.toInt() ?? 0,
      totalViews: (json['total_views'] as num?)?.toInt() ?? 0,
    );
  }

  static const empty = PropertyStatsModel(
    total: 0,
    published: 0,
    rented: 0,
    draft: 0,
    totalViews: 0,
  );
}
