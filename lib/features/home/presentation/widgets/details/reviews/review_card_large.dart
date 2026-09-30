import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/models/review_model.dart';
import 'star_rating.dart';

class ReviewCardLarge extends StatelessWidget {
  final ReviewModel review;

  const ReviewCardLarge({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
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
          // En-tête avec avatar et informations
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          review.name,
                          style: context.text.titleMedium!.copyWith(
                            color: context.tokens.foreground,
                          ),
                        ),
                        Text(review.date, style: context.text.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 4),
                    StarRating(rating: review.rating.toDouble(), starSize: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Texte du commentaire
          Text(
            review.reviewText,
            style: context.text.bodyMedium!.copyWith(
              color: context.tokens.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Détails des notes par catégorie
          _buildDetailedRatings(context),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: review.avatarColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          review.initials,
          style: context.text.titleMedium!.copyWith(color: review.textColor),
        ),
      ),
    );
  }

  Widget _buildDetailedRatings(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.tokens.background),
      child: Column(
        children: [
          _buildRatingRow(context, 'Propreté', review.cleanliness),
          const SizedBox(height: 8),
          _buildRatingRow(context, 'Emplacement', review.location),
          const SizedBox(height: 8),
          _buildRatingRow(context, 'Confort', review.comfort),
          const SizedBox(height: 8),
          _buildRatingRow(
            context,
            'Rapport qualité/prix',
            review.valueForMoney,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(BuildContext context, String label, int rating) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label, style: context.text.bodySmall)),
        Expanded(
          child: Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? LucideIcons.star : LucideIcons.star,
                size: 12,
                color: context.tokens.accentAmber,
              );
            }),
          ),
        ),
        Text(
          rating.toString(),
          style: context.text.labelMedium!.copyWith(
            color: context.tokens.foreground,
          ),
        ),
      ],
    );
  }
}
