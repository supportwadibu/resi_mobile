import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/motion/motion.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

/// Carte de tête des statistiques : le taux d'occupation en grand sur la
/// lavande, une jauge pleine largeur, le détail des logements dessous.
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
    final t = context.tokens;
    final rented = this.rented;
    final idle = this.idle;
    final rate = occupancyRate.clamp(0.0, 1.0);
    return Material(
      color: t.lavender,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: HaloSurface(
        radius: AppRadius.lg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'stats.occupancy_rate'.tr(),
                style: context.text.titleSmall!.copyWith(color: t.onLavender),
              ),
              const SizedBox(height: 18),
              CountUpText(
                '${(rate * 100).round()} %',
                style: context.text.figure.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: t.onLavender,
                ),
              ),
              const SizedBox(height: 14),
              // Jauge du taux : la part louée en plein, le reste en filigrane.
              ClipRRect(
                borderRadius: AppRadius.pill,
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: t.onLavender.withValues(alpha: 0.12)),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: rate,
                        child: ColoredBox(color: t.onLavender),
                      ),
                    ],
                  ),
                ),
              ),
              if (rented != null && idle != null) ...[
                const SizedBox(height: 12),
                Text(
                  '${'stats.units_rented'.plural(rented)} · '
                  '${'stats.units_idle'.plural(idle)}',
                  style: context.text.bodySmall!.copyWith(
                    color: t.onLavender.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
