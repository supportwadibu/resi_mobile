import 'package:easy_localization/easy_localization.dart';
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
              label: 'common.occupancy'.tr(),
              value: '${(tauxOccupation * 100).toStringAsFixed(0)} %',
              icon: LucideIcons.chartPie,
              accent: AppAccent.amber,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              compact: true,
              label: 'finance_page.bookings'.tr(),
              value: '$reservations',
              icon: AppSectionIcons.bookings,
              accent: AppAccent.violet,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              compact: true,
              label: 'finance_page.average_stay'.tr(),
              value: 'finance_page.days_short'.tr(
                args: [moyenSejour.toStringAsFixed(1)],
              ),
              icon: LucideIcons.clock,
              accent: AppAccent.blue,
            ),
          ),
        ],
      ),
    );
  }
}
