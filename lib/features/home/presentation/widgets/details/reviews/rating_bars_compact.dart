import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';

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
                    style: context.text.bodySmall,
                  ),
                  Text(
                    item.score.toString(),
                    style: context.text.labelMedium!.copyWith(color: context.tokens.foreground, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: context.tokens.border,
                ),
                child: FractionallySizedBox(
                  widthFactor: item.percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.tokens.accentAmber,
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
