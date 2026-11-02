import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double starSize;
  final bool showHalfStars;

  const StarRating({
    super.key,
    required this.rating,
    this.starSize = 14,
    this.showHalfStars = true,
  });

  @override
  Widget build(BuildContext context) {
    int fullStars = rating.floor();
    bool hasHalfStar = showHalfStars && (rating - fullStars >= 0.5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < fullStars; i++)
          Icon(
            LucideIcons.star,
            color: context.tokens.accentAmber,
            size: starSize,
          ),
        if (hasHalfStar)
          Icon(
            LucideIcons.starHalf,
            color: context.tokens.accentAmber,
            size: starSize,
          ),
        for (int i = fullStars + (hasHalfStar ? 1 : 0); i < 5; i++)
          Icon(
            LucideIcons.star,
            color: context.tokens.accentAmber,
            size: starSize,
          ),
      ],
    );
  }
}
