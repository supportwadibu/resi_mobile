import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';

class KpiRow extends StatelessWidget {
  const KpiRow({super.key, required this.entrees, required this.sorties});

  /// Chiffre d'affaires brut de la période.
  final double entrees;

  /// Dépenses engagées sur la même période.
  final double sorties;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: KpiCard(
            label: 'Entrées',
            value: CurrencyFormatter.fcfa(entrees),
            icon: FontAwesomeIcons.arrowTrendUp,
            color: const Color(0xFF14A985),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: KpiCard(
            label: 'Sorties',
            value: CurrencyFormatter.fcfa(sorties),
            icon: FontAwesomeIcons.arrowTrendDown,
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final FaIconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
