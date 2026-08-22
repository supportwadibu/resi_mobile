import 'package:flutter/material.dart';

class RatingBarsCompact extends StatelessWidget {
  const RatingBarsCompact({super.key});

  @override
  Widget build(BuildContext context) {
    final List<RatingItem> ratings = [
      RatingItem(label: 'Propreté', score: 4.9, percentage: 0.98),
      RatingItem(label: 'Emplacement', score: 4.8, percentage: 0.96),
      RatingItem(label: 'Confort', score: 4.9, percentage: 0.98),
      RatingItem(label: 'Rapport qualité/prix', score: 4.7, percentage: 0.94),
      RatingItem(label: 'Service', score: 4.8, percentage: 0.96),
      RatingItem(label: 'Équipements', score: 4.7, percentage: 0.94),
    ];

    return Column(
      children: ratings.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  Text(
                    item.score.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  widthFactor: item.percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class RatingItem {
  final String label;
  final double score;
  final double percentage;

  RatingItem({
    required this.label,
    required this.score,
    required this.percentage,
  });
}
