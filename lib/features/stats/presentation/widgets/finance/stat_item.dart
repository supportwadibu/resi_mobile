import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

class StatItem extends StatelessWidget {
  final String label;
  final String value;

  const StatItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.statLabel),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.statValue),
      ],
    );
  }
}
