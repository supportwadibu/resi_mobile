import 'package:flutter/material.dart';

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
      hint: Text(hint ?? 'Choisir un bien'),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xffF5F5FA),
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
