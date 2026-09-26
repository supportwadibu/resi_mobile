import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/reservation/data/models/booking_stats_model.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';
import 'package:resi_africa/shared/widgets/status_badge.dart';

class ReservationStatsRow extends StatelessWidget {
  const ReservationStatsRow({super.key, this.stats});

  /// `null` tant que les chiffres ne sont pas arrivés — les tuiles gardent
  /// alors leur gabarit et affichent un tiret, pour que la page ne tressaute
  /// pas au chargement.
  final BookingStatsModel? stats;

  @override
  Widget build(BuildContext context) {
    final stats = this.stats;

    // Les séjours à venir et en cours prennent la couleur de leur statut
    // (planifié bleu, en cours violet) : la tuile se lit comme le badge des
    // lignes juste en dessous.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatTile(
              compact: true,
              label: 'Occupation',
              value: stats == null ? '—' : '${stats.occupancyPercent} %',
              icon: LucideIcons.chartPie,
              accent: AppAccent.amber,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              compact: true,
              label: 'À venir',
              value: stats == null ? '—' : '${stats.upcoming}',
              icon: LucideIcons.calendarClock,
              accent: StatusTone.upcoming.accent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              compact: true,
              label: 'En cours',
              value: stats == null ? '—' : '${stats.inProgress}',
              icon: LucideIcons.bedDouble,
              accent: StatusTone.ongoing.accent,
            ),
          ),
        ],
      ),
    );
  }
}
