import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/features/home/presentation/widgets/reservations/stat_card.dart';

class ReservationStatsRow extends StatelessWidget {
  const ReservationStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: StatCard(
            label: 'Taux occupation',
            value: '78%',
            icon: FontAwesomeIcons.chartPie,
            color: Color(0xFF3322AC),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'En attente',
            value: '4',
            icon: FontAwesomeIcons.clockRotateLeft,
            color: Color(0xFFF59E0B),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Confirmées',
            value: '12',
            icon: FontAwesomeIcons.circleCheck,
            color: Color(0xFF14A985),
          ),
        ),
      ],
    );
  }
}
