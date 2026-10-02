import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
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
  String selectedFilter = 'reviews.all'.tr();
  int selectedRating = 0;

  final List<String> filters = [
    'reviews.all'.tr(),
    for (var stars = 5; stars >= 1; stars--) 'reviews.stars'.plural(stars),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'reviews.title'.tr()),
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
