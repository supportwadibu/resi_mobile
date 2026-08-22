import 'package:flutter/material.dart';
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
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and name
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 10),
              _buildUserInfo(),
            ],
          ),
          const SizedBox(height: 8),
          const StarRating(rating: 5.0, starSize: 12),
          const SizedBox(height: 8),
          _buildReviewText(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
        ),
        Text(date, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildReviewText() {
    return Text(
      reviewText,
      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.6),
    );
  }
}
