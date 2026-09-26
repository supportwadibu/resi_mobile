import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

class OccupancyCard extends StatelessWidget {
  const OccupancyCard({
    super.key,
    required this.occupancyRate,
    this.rented,
    this.available,
  });

  /// Taux d'occupation de la période, en fraction de 0 à 1 — l'échelle servie
  /// par `taux_occupation`, convertie ici à l'affichage.
  final double occupancyRate;

  /// Unités occupées et unités publiées encore libres, à l'instant présent —
  /// ces deux compteurs ne dépendent pas de la période du taux.
  ///
  /// Nuls chez le gérant : ils viennent de `/proprio/properties/stats`, fermée
  /// à son rôle. La note disparaît alors, plutôt que d'afficher deux zéros
  /// qui se liraient comme un parc vide.
  final int? rented;
  final int? available;

  @override
  Widget build(BuildContext context) {
    final rented = this.rented;
    final available = this.available;
    return StatTile(
      label: 'Taux d\'occupation',
      value: '${(occupancyRate * 100).round()} %',
      icon: LucideIcons.chartPie,
      accent: AppAccent.amber,
      note: rented != null && available != null
          ? '$rented ${rented > 1 ? 'unités louées' : 'unité louée'} · '
                '$available ${available > 1 ? 'disponibles' : 'disponible'}'
          : null,
    );
  }
}
