import 'package:flutter/material.dart';
import 'package:resi_africa/shared/models/review_model.dart';
import 'review_card_large.dart';

class AllReviewsList extends StatelessWidget {
  final String selectedFilter;
  final int selectedRating;

  const AllReviewsList({
    super.key,
    required this.selectedFilter,
    required this.selectedRating,
  });

  @override
  Widget build(BuildContext context) {
    final reviews = _getFilteredReviews();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return ReviewCardLarge(review: reviews[index]);
      },
    );
  }

  List<ReviewModel> _getFilteredReviews() {
    List<ReviewModel> allReviews = [
      ReviewModel(
        id: '1',
        name: 'Ama Koné',
        initials: 'AK',
        date: 'Mai 2026',
        rating: 5,
        avatarColor: const Color(0xFFE6F1FB),
        textColor: const Color(0xFF185FA5),
        reviewText:
            'Logement impeccable, très bien situé. L\'hôte est réactif et attentionné. Je recommande vivement.',
        cleanliness: 5,
        location: 5,
        comfort: 5,
        valueForMoney: 5,
      ),
      ReviewModel(
        id: '2',
        name: 'Moussa Bamba',
        initials: 'MB',
        date: 'Avril 2026',
        rating: 5,
        avatarColor: const Color(0xFFEEEDFE),
        textColor: const Color(0xFF534AB7),
        reviewText:
            'Séjour parfait. Propre, confortable et calme. Le quartier est idéal pour se déplacer facilement.',
        cleanliness: 5,
        location: 5,
        comfort: 5,
        valueForMoney: 4,
      ),
      ReviewModel(
        id: '3',
        name: 'Fatima Diallo',
        initials: 'FD',
        date: 'Avril 2026',
        rating: 4,
        avatarColor: const Color(0xFFFEF3C7),
        textColor: const Color(0xFFD97706),
        reviewText:
            'Très bon séjour dans l\'ensemble. L\'appartement est spacieux et bien équipé. Petit bémol sur l\'isolation sonore.',
        cleanliness: 4,
        location: 5,
        comfort: 4,
        valueForMoney: 4,
      ),
      ReviewModel(
        id: '4',
        name: 'Jean Dupont',
        initials: 'JD',
        date: 'Mars 2026',
        rating: 5,
        avatarColor: const Color(0xFFE0F2FE),
        textColor: const Color(0xFF0284C7),
        reviewText:
            'Excellent emplacement, proche de toutes commodités. L\'hôte très accueillant.',
        cleanliness: 5,
        location: 5,
        comfort: 5,
        valueForMoney: 5,
      ),
      ReviewModel(
        id: '5',
        name: 'Marie Lambert',
        initials: 'ML',
        date: 'Mars 2026',
        rating: 4,
        avatarColor: const Color(0xFFFCE7F3),
        textColor: const Color(0xFFDB2777),
        reviewText:
            'Bien situé et propre. Manque juste quelques ustensiles de cuisine supplémentaires.',
        cleanliness: 4,
        location: 4,
        comfort: 4,
        valueForMoney: 4,
      ),
    ];

    if (selectedFilter != 'Tous') {
      int rating = int.parse(selectedFilter.split(' ')[0]);
      allReviews = allReviews
          .where((review) => review.rating == rating)
          .toList();
    }

    return allReviews;
  }
}
