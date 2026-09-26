import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

class KpiRow extends StatelessWidget {
  const KpiRow({super.key, required this.entrees, required this.sorties});

  /// Chiffre d'affaires brut de la période.
  final double entrees;

  /// Dépenses engagées sur la même période.
  final double sorties;

  @override
  Widget build(BuildContext context) {
    return StatGrid(
      children: [
        StatTile(
          label: 'Entrées',
          value: CurrencyFormatter.fcfa(entrees),
          icon: LucideIcons.trendingUp,
          accent: AppAccent.green,
        ),
        StatTile(
          label: 'Sorties',
          value: CurrencyFormatter.fcfa(sorties),
          icon: LucideIcons.trendingDown,
          accent: AppAccent.red,
        ),
      ],
    );
  }
}
