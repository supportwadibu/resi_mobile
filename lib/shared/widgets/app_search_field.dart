import 'package:flutter/material.dart';
import 'app_text_field.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    required this.onTap,
    this.hint = 'Rechercher...',
    this.padding,
    super.key,
  });

  final VoidCallback onTap;
  final String? hint;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: '',
      hint: hint,
      readOnly: true,
      onTap: onTap,
      padding: padding,
      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
      suffixIcon: const SizedBox.shrink(), // pas de chevron
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    );
  }
}