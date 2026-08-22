import 'package:flutter/material.dart';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec avatar et informations
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          review.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Détails des notes par catégorie
          _buildDetailedRatings(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: review.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedRatings() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildRatingRow('Propreté', review.cleanliness),
          const SizedBox(height: 8),
          _buildRatingRow('Emplacement', review.location),
          const SizedBox(height: 8),
          _buildRatingRow('Confort', review.comfort),
          const SizedBox(height: 8),
          _buildRatingRow('Rapport qualité/prix', review.valueForMoney),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String label, int rating) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                size: 12,
                color: const Color(0xFFF59E0B),
              );
            }),
          ),
        ),
        Text(
          rating.toString(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}
