import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'star_rating.dart';
import 'rating_bars_compact.dart';

class ReviewsSummaryCard extends StatelessWidget {
  const ReviewsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: context.tokens.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score global
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text(
                  '4,9',
                  style: context.text.headlineSmall!.copyWith(
                    color: context.tokens.foreground,
                  ),
                ),
                const SizedBox(height: 8),
                const StarRating(rating: 4.9, starSize: 18),
                const SizedBox(height: 8),
                Text('reviews.count'.tr(args: ['128']), style: context.mutedText),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 100,
            color: context.tokens.border,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Barres de notes
          const Expanded(flex: 2, child: RatingBarsCompact()),
        ],
      ),
    );
  }
}
