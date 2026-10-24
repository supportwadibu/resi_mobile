import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

class OccupancyCard extends StatelessWidget {
  const OccupancyCard({
    super.key,
    required this.occupancyRate,
    this.rented,
    this.idle,
  });

  /// Taux d'occupation de la période, en fraction de 0 à 1 — l'échelle servie
  /// par `taux_occupation`, convertie ici à l'affichage.
  final double occupancyRate;

  /// Logements ayant porté au moins un séjour sur la période, et ceux qui
  /// n'en ont porté aucun — la même fenêtre que le taux, si bien que la note
  /// suit le mois choisi.
  ///
  /// Nuls chez le gérant, dont le relevé ne les porte pas, ou face à un
  /// serveur qui ne les sert pas encore. La note disparaît alors, plutôt que
  /// d'afficher deux zéros qui se liraient comme un parc vide.
  final int? rented;
  final int? idle;

  @override
  Widget build(BuildContext context) {
    final rented = this.rented;
    final idle = this.idle;
    return StatTile(
      label: 'stats.occupancy_rate'.tr(),
      value: '${(occupancyRate * 100).round()} %',
      icon: LucideIcons.chartPie,
      accent: AppAccent.amber,
      note: rented != null && idle != null
          ? '${'stats.units_rented'.plural(rented)} · '
                '${'stats.units_idle'.plural(idle)}'
          : null,
    );
  }
}
