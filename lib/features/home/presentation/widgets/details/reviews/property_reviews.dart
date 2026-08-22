import 'package:flutter/material.dart';
import 'reviews_header.dart';
import 'rating_bars_grid.dart';
import 'reviews_cards.dart';

class PropertyReviews extends StatelessWidget {
  const PropertyReviews({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReviewsHeader(),
        SizedBox(height: 20),
        RatingBarsGrid(),
        SizedBox(height: 20),
        ReviewsCards(),
      ],
    );
  }
}
