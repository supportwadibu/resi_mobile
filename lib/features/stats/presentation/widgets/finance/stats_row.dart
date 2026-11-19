import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

/// Occupation, séjours et durée moyenne de la période : une carte à trois
/// lignes, libellé à gauche et chiffre à droite. Trois tuiles sur une même
/// ligne coupaient chaque libellé en deux.
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
    return Section(
      title: 'finance_page.activity'.tr(),
      icon: LucideIcons.activity,
      child: Column(
        children: [
          _Line(
            icon: LucideIcons.chartPie,
            label: 'common.occupancy'.tr(),
            value: '${(tauxOccupation * 100).toStringAsFixed(0)} %',
          ),
          const SizedBox(height: 14),
          _Line(
            icon: AppSectionIcons.bookings,
            label: 'finance_page.bookings'.tr(),
            value: '$reservations',
          ),
          const SizedBox(height: 14),
          _Line(
            icon: LucideIcons.clock,
            label: 'finance_page.average_stay'.tr(),
            value: 'finance_page.days_short'.tr(
              args: [moyenSejour.toStringAsFixed(1)],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconChip(icon: icon, size: 40),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: context.text.titleSmall)),
        const SizedBox(width: 12),
        Text(
          value,
          style: context.text.figure.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
