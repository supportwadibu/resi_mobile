import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';

class RatingDistributionChart extends StatelessWidget {
  const RatingDistributionChart({super.key});

  @override
  Widget build(BuildContext context) {
    final List<RatingDistribution> distributions = [
      RatingDistribution(stars: 5, count: 98, percentage: 0.76),
      RatingDistribution(stars: 4, count: 25, percentage: 0.19),
      RatingDistribution(stars: 3, count: 5, percentage: 0.04),
      RatingDistribution(stars: 2, count: 0, percentage: 0),
      RatingDistribution(stars: 1, count: 0, percentage: 0),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: context.tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'reviews.distribution'.tr(),
            style: context.text.titleMedium!.copyWith(
              color: context.tokens.foreground,
            ),
          ),
          const SizedBox(height: 16),
          ...distributions.map(
            (dist) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDistributionBar(context, dist),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(BuildContext context, RatingDistribution dist) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Row(
            children: [
              Text('${dist.stars}', style: context.text.titleSmall),
              Icon(
                LucideIcons.star,
                size: 14,
                color: context.tokens.accentAmber,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.tokens.border,
              borderRadius: AppRadius.pill,
            ),
            child: FractionallySizedBox(
              widthFactor: dist.percentage,
              child: Container(
                decoration: BoxDecoration(color: context.tokens.accentAmber),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '${dist.count}',
            style: context.mutedText,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class RatingDistribution {
  final int stars;
  final int count;
  final double percentage;

  RatingDistribution({
    required this.stars,
    required this.count,
    required this.percentage,
  });
}
