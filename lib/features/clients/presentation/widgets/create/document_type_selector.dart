import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';

import '../../../data/models/client_model.dart';

/// Choix de la nature de la pièce : CNI, passeport, permis.
///
/// Partagé par la création et la modification d'une fiche : la lecture de la
/// pièce le présélectionne, le propriétaire le corrige.
class DocumentTypeSelector extends StatelessWidget {
  const DocumentTypeSelector({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final ClientIdDocumentType? selected;
  final ValueChanged<ClientIdDocumentType> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ClientIdDocumentType.values
          .map((type) {
            final isSelected = type == selected;
            return GestureDetector(
              onTap: () => onSelect(type),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.tokens.foreground
                      : context.tokens.surface,
                  borderRadius: AppRadius.md,
                  border: Border.all(
                    color: isSelected
                        ? context.tokens.foreground
                        : context.tokens.border,
                  ),
                ),
                child: Text(
                  type.label,
                  style: context.text.titleSmall!.copyWith(
                    color: isSelected ? context.tokens.background : null,
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
