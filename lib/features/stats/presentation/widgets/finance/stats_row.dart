import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'stat_item.dart';

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
    final taux = '${(tauxOccupation * 100).toStringAsFixed(0)}%';
    final moyen = '${moyenSejour.toStringAsFixed(1)} j';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistiques', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StatItem(label: "Taux d'occ.", value: taux),
            _Divider(),
            StatItem(label: 'Réservations', value: '$reservations'),
            _Divider(),
            StatItem(label: 'Moy. Séjour', value: moyen),
          ],
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 36, width: 1, color: AppColors.divider);
  }
}
