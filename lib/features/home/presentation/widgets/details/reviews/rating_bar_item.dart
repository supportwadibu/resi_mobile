import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';

class RatingBarItem extends StatelessWidget {
  final String label;
  final double score;
  final double percentage;

  const RatingBarItem({
    super.key,
    required this.label,
    required this.score,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: context.text.bodySmall,
            ),
            Text(
              score.toString(),
              style: context.text.titleSmall!.copyWith(color: context.tokens.foreground),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Progress bar
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: context.tokens.border,
          ),
          child: FractionallySizedBox(
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: context.tokens.accentAmber,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
