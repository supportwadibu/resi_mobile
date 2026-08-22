import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
                const Text(
                  '4,9',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '/ 5',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),

        // Vertical divider
        Container(
          width: 1,
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          color: Colors.grey.shade300,
        ),

        // Meta information
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Excellent',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                'Basé sur 128 avis',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        fontSize: 12,
        trailingIcon: AppButtonIcon.fa(FontAwesomeIcons.chevronRight, size: 12),
      ),
    );
  }
}
