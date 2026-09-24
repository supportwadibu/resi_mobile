import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/features/home/presentation/widgets/reservations/stat_card.dart';
import 'package:resi_africa/features/reservation/data/models/booking_stats_model.dart';

class ReservationStatsRow extends StatelessWidget {
  const ReservationStatsRow({super.key, this.stats});

  /// `null` tant que les chiffres ne sont pas arrivés — les tuiles gardent
  /// alors leur gabarit et affichent un tiret, pour que la page ne tressaute
  /// pas au chargement.
  final BookingStatsModel? stats;

  @override
  Widget build(BuildContext context) {
    final stats = this.stats;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Taux occupation',
            value: stats == null ? '—' : '${stats.occupancyPercent}%',
            icon: FontAwesomeIcons.chartPie,
            color: const Color(0xFF3322AC),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'À venir',
            value: stats == null ? '—' : '${stats.upcoming}',
            icon: FontAwesomeIcons.clockRotateLeft,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'En cours',
            value: stats == null ? '—' : '${stats.inProgress}',
            icon: FontAwesomeIcons.circleCheck,
            color: const Color(0xFF14A985),
          ),
        ),
      ],
    );
  }
}
