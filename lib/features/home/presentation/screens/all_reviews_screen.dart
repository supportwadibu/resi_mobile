import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../widgets/details/reviews/all_reviews_list.dart';
import '../widgets/details/reviews/rating_distribution_chart.dart';
import '../widgets/details/reviews/reviews_filter_bar.dart';
import '../widgets/details/reviews/reviews_summary_card.dart';

@RoutePage()
class AllReviewsScreen extends StatefulWidget {
  const AllReviewsScreen({super.key});

  @override
  State<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends State<AllReviewsScreen> {
  String selectedFilter = 'Tous';
  int selectedRating = 0;

  final List<String> filters = [
    'Tous',
    '5 étoiles',
    '4 étoiles',
    '3 étoiles',
    '2 étoiles',
    '1 étoile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes & avis', style: TextStyle(fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Résumé des notes
              const ReviewsSummaryCard(),
              const SizedBox(height: 24),

              // Distribution des notes
              const RatingDistributionChart(),
              const SizedBox(height: 24),

              // Filtres
              ReviewsFilterBar(
                filters: filters,
                selectedFilter: selectedFilter,
                onFilterChanged: (filter) {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Liste des avis
              AllReviewsList(
                selectedFilter: selectedFilter,
                selectedRating: selectedRating,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
