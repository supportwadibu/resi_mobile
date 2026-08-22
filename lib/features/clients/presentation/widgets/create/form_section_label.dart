import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

class FormSectionLabel extends StatelessWidget {
  final String text;

  const FormSectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: AppTextStyles.sectionTitle),
    );
  }
}
