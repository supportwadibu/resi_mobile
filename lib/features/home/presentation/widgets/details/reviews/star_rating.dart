import 'package:flutter/material.dart';

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
          Icon(Icons.star, color: const Color(0xFFF59E0B), size: starSize),
        if (hasHalfStar)
          Icon(Icons.star_half, color: const Color(0xFFF59E0B), size: starSize),
        for (int i = fullStars + (hasHalfStar ? 1 : 0); i < 5; i++)
          Icon(
            Icons.star_border,
            color: const Color(0xFFF59E0B),
            size: starSize,
          ),
      ],
    );
  }
}
