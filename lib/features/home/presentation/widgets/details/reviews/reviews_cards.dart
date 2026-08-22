import 'package:flutter/material.dart';
import 'review_card.dart';

class ReviewsCards extends StatelessWidget {
  const ReviewsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ReviewCard(
          name: 'Ama Koné',
          initials: 'AK',
          date: 'Mai 2026',
          avatarColor: Color(0xFFE6F1FB),
          textColor: Color(0xFF185FA5),
          reviewText:
              'Logement impeccable, très bien situé. L\'hôte est réactif et attentionné. Je recommande vivement.',
        ),
        SizedBox(height: 12),
        ReviewCard(
          name: 'Moussa Bamba',
          initials: 'MB',
          date: 'Avril 2026',
          avatarColor: Color(0xFFEEEDFE),
          textColor: Color(0xFF534AB7),
          reviewText:
              'Séjour parfait. Propre, confortable et calme. Le quartier est idéal pour se déplacer facilement.',
        ),
      ],
    );
  }
}
