import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'star_rating.dart';

class ReviewsHeader extends StatelessWidget {
  final VoidCallback? onViewAllPressed;

  const ReviewsHeader({super.key, this.onViewAllPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Stars and score
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StarRating(rating: 4.9, starSize: 14),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '4,9',
                  style: context.text.headlineSmall!.copyWith(
                    color: context.tokens.foreground,
                  ),
                ),
                const SizedBox(width: 2),
                Text('/ 5', style: context.mutedText),
              ],
            ),
          ],
        ),

        // Vertical divider
        Container(
          width: 1,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: context.tokens.border,
        ),

        // Meta information
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Excellent',
                style: context.text.titleSmall!.copyWith(
                  color: context.tokens.foreground,
                ),
              ),
              Text('Basé sur 128 avis', style: context.text.bodySmall),
            ],
          ),
        ),

        // "Voir tous" button
        _buildViewAllButton(context),
      ],
    );
  }

  Widget _buildViewAllButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onViewAllPressed != null) {
          onViewAllPressed!();
        } else {
          //
        }
      },
      child: AppButton(
        label: 'Voir tous',
        variant: AppButtonVariant.secondary,
        onPressed: () => context.router.push(const AllReviewsRoute()),
        size: AppButtonSize.sm,
        trailingIcon: LucideIcons.chevronRight,
      ),
    );
  }
}
