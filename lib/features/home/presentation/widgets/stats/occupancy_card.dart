import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OccupancyCard extends StatelessWidget {
  const OccupancyCard({
    super.key,
    required this.occupancyRate,
    this.rented,
    this.available,
  });

  /// Taux d'occupation de la période, en fraction de 0 à 1 — l'échelle servie
  /// par `taux_occupation`, convertie ici à l'affichage.
  final double occupancyRate;

  /// Unités occupées et unités publiées encore libres, à l'instant présent —
  /// ces deux compteurs ne dépendent pas de la période du taux.
  ///
  /// Nuls chez le gérant : ils viennent de `/proprio/properties/stats`, fermée
  /// à son rôle. La ligne disparaît alors, plutôt que d'afficher deux zéros
  /// qui se liraient comme un parc vide.
  final int? rented;
  final int? available;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3322AC), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Taux d\'occupation',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(occupancyRate * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (rented != null && available != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OccupancyStat(label: 'Unités louées', value: '$rented'),
                      const SizedBox(width: 24),
                      OccupancyStat(label: 'Disponibles', value: '$available'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
              Positioned(
                right: -10,
                top: -10,
                child: FaIcon(
                  FontAwesomeIcons.chartPie,
                  size: 60,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: FaIcon(
                    FontAwesomeIcons.chartPie,
                    size: 28,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OccupancyStat extends StatelessWidget {
  const OccupancyStat({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
