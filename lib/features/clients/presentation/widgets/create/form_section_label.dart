import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';

/// Libellé d'un champ de formulaire, au style des libellés d'`AppTextField`.
class FormSectionLabel extends StatelessWidget {
  final String text;

  const FormSectionLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: context.text.titleSmall),
    );
  }
}
