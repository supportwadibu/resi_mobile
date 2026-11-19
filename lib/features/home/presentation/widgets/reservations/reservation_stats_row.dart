import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/reservation/data/models/booking_stats_model.dart';
import 'package:resi_africa/shared/widgets/status_badge.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

/// Occupation, séjours à venir et en cours du mois : une carte à trois
/// lignes, libellé en entier à gauche et chiffre à droite. Trois tuiles sur
/// une même ligne coupaient les libellés.
class ReservationStatsRow extends StatelessWidget {
  const ReservationStatsRow({super.key, this.stats});

  /// `null` tant que les chiffres ne sont pas arrivés — les lignes gardent
  /// alors leur gabarit et affichent un tiret, pour que la page ne tressaute
  /// pas au chargement.
  final BookingStatsModel? stats;

  @override
  Widget build(BuildContext context) {
    final stats = this.stats;
    // Les séjours à venir et en cours prennent la couleur de leur statut
    // (planifié bleu, en cours violet) : la ligne se lit comme le badge des
    // réservations.
    return Section(
      title: 'reservation.month_activity'.tr(),
      icon: LucideIcons.activity,
      child: Column(
        children: [
          _Line(
            icon: LucideIcons.chartPie,
            accent: AppAccent.neutral,
            label: 'common.occupancy'.tr(),
            value: stats == null ? '—' : '${stats.occupancyPercent} %',
          ),
          const SizedBox(height: 14),
          _Line(
            icon: LucideIcons.calendarClock,
            accent: StatusTone.upcoming.accent,
            label: 'home.upcoming'.tr(),
            value: stats == null ? '—' : '${stats.upcoming}',
          ),
          const SizedBox(height: 14),
          _Line(
            icon: LucideIcons.bedDouble,
            accent: StatusTone.ongoing.accent,
            label: 'home.in_progress'.tr(),
            value: stats == null ? '—' : '${stats.inProgress}',
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final AppAccent accent;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconChip(icon: icon, accent: accent, size: 40),
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
