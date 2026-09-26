import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'star_rating.dart';

class ReviewCard extends StatelessWidget {
  final String name;
  final String initials;
  final String date;
  final Color avatarColor;
  final Color textColor;
  final String reviewText;

  const ReviewCard({
    super.key,
    required this.name,
    required this.initials,
    required this.date,
    required this.avatarColor,
    required this.textColor,
    required this.reviewText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tokens.surface,
        border: Border.all(color: context.tokens.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and name
          Row(
            children: [
              _buildAvatar(context),
              const SizedBox(width: 10),
              _buildUserInfo(context),
            ],
          ),
          const SizedBox(height: 8),
          const StarRating(rating: 5.0, starSize: 12),
          const SizedBox(height: 8),
          _buildReviewText(context),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: avatarColor, shape: BoxShape.rectangle),
      child: Center(
        child: Text(
          initials,
          style: context.text.titleSmall!.copyWith(color: textColor),
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: context.text.titleSmall!.copyWith(color: context.tokens.foreground),
        ),
        Text(date, style: context.text.bodySmall),
      ],
    );
  }

  Widget _buildReviewText(BuildContext context) {
    return Text(
      reviewText,
      style: context.text.bodyMedium!.copyWith(color: context.tokens.muted, height: 1.6),
    );
  }
}
