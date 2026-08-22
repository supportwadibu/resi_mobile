import 'package:flutter/material.dart';
import 'star_rating.dart';
import 'rating_bars_compact.dart';

class ReviewsSummaryCard extends StatelessWidget {
  const ReviewsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score global
          Expanded(
            flex: 1,
            child: Column(
              children: [
                const Text(
                  '4,9',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const StarRating(rating: 4.9, starSize: 18),
                const SizedBox(height: 8),
                Text(
                  '128 avis',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 100,
            color: Colors.grey.shade200,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Barres de notes
          const Expanded(flex: 2, child: RatingBarsCompact()),
        ],
      ),
    );
  }
}
