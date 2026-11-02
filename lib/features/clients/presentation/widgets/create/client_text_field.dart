import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';

/// Champ de la fiche client. Bordures, fond et message d'erreur viennent de
/// `inputDecorationTheme`.
class ClientTextField extends StatelessWidget {
  final String hint;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;
  final String? errorText;

  /// Fourni à l'édition, pour présenter la valeur existante. Absent à la
  /// création, où le champ part vide.
  final TextEditingController? controller;

  const ClientTextField({
    super.key,
    required this.hint,
    required this.prefixIcon,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: context.text.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(prefixIcon, size: 16),
        errorText: errorText,
      ),
    );
  }
}
