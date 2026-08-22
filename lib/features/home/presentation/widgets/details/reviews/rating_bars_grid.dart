import 'package:flutter/material.dart';
import 'rating_bar_item.dart';

class RatingBarsGrid extends StatelessWidget {
  const RatingBarsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 4.5,
      children: const [
        RatingBarItem(label: 'Propreté', score: 4.9, percentage: 0.98),
        RatingBarItem(label: 'Emplacement', score: 4.8, percentage: 0.96),
        RatingBarItem(label: 'Confort', score: 4.9, percentage: 0.98),
        RatingBarItem(
          label: 'Rapport qualité/prix',
          score: 4.7,
          percentage: 0.94,
        ),
      ],
    );
  }
}
