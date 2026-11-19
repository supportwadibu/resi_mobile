import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/subscription/presentation/widgets/plan_gate.dart';
import 'package:resi_africa/features/subscription/presentation/widgets/plan_style.dart';
import 'package:resi_africa/shared/motion/motion.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

/// Entrées et sorties de la période, deux tuiles côte à côte : les entrées
/// sur le sable, les sorties neutres.
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
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            label: 'stats.income'.tr(),
            value: CurrencyFormatter.short(entrees),
            icon: LucideIcons.trendingUp,
            sand: true,
          ),
        ),
        const SizedBox(width: 10),
        // Tuile gardée et verrouillée plutôt que retirée : un tiret et l'offre
        // qui l'ouvre disent ce qui manque, là où une absence ne dit rien — et
        // un zéro se lirait comme « aucune dépense ».
        Expanded(
          child: sorties == null
              ? _KpiTile(
                  label: 'stats.outflow'.tr(),
                  value: '—',
                  icon: LucideIcons.lock,
                  note: 'stats.outflow_locked'.tr(),
                  onTap: () => ensurePlanFor(context, PremiumFeature.expenses),
                )
              : _KpiTile(
                  label: 'stats.outflow'.tr(),
                  value: CurrencyFormatter.short(sorties),
                  icon: LucideIcons.trendingDown,
                ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    this.note,
    this.onTap,
    this.sand = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? note;
  final VoidCallback? onTap;
  final bool sand;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = sand ? t.onSand : t.foreground;
    final body = SizedBox(
      height: 132,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium!.copyWith(color: fg),
                  ),
                ),
                const Spacer(),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: sand ? t.onOverlay : t.background,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 34,
                    child: Icon(icon, size: 15, color: sand ? t.onSand : fg),
                  ),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: CountUpText(
                value,
                style: context.text.figure.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
            if (note != null)
              Text(
                note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall,
              ),
          ],
        ),
      ),
    );
    return Material(
      color: sand ? t.sand : t.surface,
      shape: AppRadius.outlined(AppRadius.lg, sand ? t.sand : t.border),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: HaloSurface(radius: AppRadius.lg, child: body),
      ),
    );
  }
}
