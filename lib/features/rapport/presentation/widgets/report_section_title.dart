import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class ReportSectionTitle extends StatelessWidget {
  final String title;

  const ReportSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: AppTextStyles.sectionTitle),
    );
  }
}