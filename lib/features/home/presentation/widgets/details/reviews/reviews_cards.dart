import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'review_card.dart';

class ReviewsCards extends StatelessWidget {
  const ReviewsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReviewCard(
          name: 'Ama Koné',
          initials: 'AK',
          date: 'Mai 2026',
          avatarColor: context.tokens.accentBlueSoft,
          textColor: context.tokens.accentBlue,
          reviewText:
              'Logement impeccable, très bien situé. L\'hôte est réactif et attentionné. Je recommande vivement.',
        ),
        SizedBox(height: 12),
        ReviewCard(
          name: 'Moussa Bamba',
          initials: 'MB',
          date: 'Avril 2026',
          avatarColor: context.tokens.accentVioletSoft,
          textColor: context.tokens.accentViolet,
          reviewText:
              'Séjour parfait. Propre, confortable et calme. Le quartier est idéal pour se déplacer facilement.',
        ),
      ],
    );
  }
}
