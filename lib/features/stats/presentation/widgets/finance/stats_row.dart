import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

/// Occupation, séjours et durée moyenne de la période, en trois tuiles
/// étroites.
class StatsRow extends StatelessWidget {
  final double tauxOccupation;
  final int reservations;
  final double moyenSejour;

  const StatsRow({
    super.key,
    required this.tauxOccupation,
    required this.reservations,
    required this.moyenSejour,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatTile(
              compact: true,
              label: 'Occupation',
              value: '${(tauxOccupation * 100).toStringAsFixed(0)} %',
              icon: LucideIcons.chartPie,
              accent: AppAccent.amber,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              compact: true,
              label: 'Réservations',
              value: '$reservations',
              icon: AppSectionIcons.bookings,
              accent: AppAccent.violet,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              compact: true,
              label: 'Séjour moyen',
              value: '${moyenSejour.toStringAsFixed(1)} j',
              icon: LucideIcons.clock,
              accent: AppAccent.blue,
            ),
          ),
        ],
      ),
    );
  }
}
