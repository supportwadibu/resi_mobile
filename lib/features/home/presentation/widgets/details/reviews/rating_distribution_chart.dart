import 'package:flutter/material.dart';

class RatingDistributionChart extends StatelessWidget {
  const RatingDistributionChart({super.key});

  @override
  Widget build(BuildContext context) {
    final List<RatingDistribution> distributions = [
      RatingDistribution(stars: 5, count: 98, percentage: 0.76),
      RatingDistribution(stars: 4, count: 25, percentage: 0.19),
      RatingDistribution(stars: 3, count: 5, percentage: 0.04),
      RatingDistribution(stars: 2, count: 0, percentage: 0),
      RatingDistribution(stars: 1, count: 0, percentage: 0),
    ];

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
          const Text(
            'Distribution des notes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...distributions.map(
            (dist) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDistributionBar(dist),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar(RatingDistribution dist) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Row(
            children: [
              Text(
                '${dist.stars}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: dist.percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            '${dist.count}',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class RatingDistribution {
  final int stars;
  final int count;
  final double percentage;

  RatingDistribution({
    required this.stars,
    required this.count,
    required this.percentage,
  });
}
