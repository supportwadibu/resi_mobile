import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/subscription/presentation/widgets/plan_gate.dart';
import 'package:resi_africa/features/subscription/presentation/widgets/plan_style.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

class KpiRow extends StatelessWidget {
  const KpiRow({super.key, required this.entrees, required this.sorties});

  /// Chiffre d'affaires brut de la période.
  final double entrees;

  /// Dépenses engagées sur la même période ; `null` sous RESI Basic, où le
  /// suivi des dépenses n'est pas inclus.
  final double? sorties;

  @override
  Widget build(BuildContext context) {
    final sorties = this.sorties;

    return StatGrid(
      children: [
        StatTile(
          label: 'stats.income'.tr(),
          value: CurrencyFormatter.fcfa(entrees),
          icon: LucideIcons.trendingUp,
          accent: AppAccent.green,
        ),
        // Tuile gardée et verrouillée plutôt que retirée : un tiret et l'offre
        // qui l'ouvre disent ce qui manque, là où une absence ne dit rien — et
        // un zéro se lirait comme « aucune dépense ».
        if (sorties == null)
          StatTile(
            label: 'stats.outflow'.tr(),
            value: '—',
            icon: LucideIcons.trendingDown,
            note: 'stats.outflow_locked'.tr(),
            onTap: () => ensurePlanFor(context, PremiumFeature.expenses),
          )
        else
          StatTile(
            label: 'stats.outflow'.tr(),
            value: CurrencyFormatter.fcfa(sorties),
            icon: LucideIcons.trendingDown,
            accent: AppAccent.red,
          ),
      ],
    );
  }
}
