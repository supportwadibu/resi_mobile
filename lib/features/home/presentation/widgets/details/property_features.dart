import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

class PropertyFeatures extends StatelessWidget {
  const PropertyFeatures({super.key, required this.features});

  final List<PropertyFeature> features;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: features
            .asMap()
            .entries
            .map(
              (e) => Padding(
                padding: EdgeInsets.only(left: e.key == 0 ? 0 : 12),
                child: _buildFeatureChip(e.value),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFeatureChip(PropertyFeature feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(feature.icon, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            '${feature.count} ${feature.label}',
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class PropertyFeature {
  const PropertyFeature({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;
}
