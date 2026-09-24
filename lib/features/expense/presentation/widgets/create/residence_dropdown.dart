import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';

/// Bien auquel imputer la dépense.
///
/// La valeur portée est l'identifiant, pas le libellé : deux biens peuvent
/// partager un nom, et c'est l'identifiant qu'attend l'API.
class ResidenceOption {
  const ResidenceOption({required this.id, required this.label});

  final String id;
  final String label;
}

class ResidenceDropdown extends StatelessWidget {
  final String? value;
  final List<ResidenceOption> residences;
  final ValueChanged<String?> onChanged;
  final String? hint;

  const ResidenceDropdown({
    super.key,
    required this.value,
    required this.residences,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      hint: Text(hint ?? 'Choisir un bien', style: AppTextStyles.labelMedium),
      style: AppTextStyles.valueSmall,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textSecondary,
      ),
      borderRadius: BorderRadius.circular(14),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: residences
          .map(
            (e) => DropdownMenuItem(
              value: e.id,
              child: Text(e.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: residences.isEmpty ? null : onChanged,
    );
  }
}
