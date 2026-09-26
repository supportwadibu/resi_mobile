import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

/// Compteur des jours ajoutés au séjour.
class NightCounter extends StatelessWidget {
  final int value;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const NightCounter({
    super.key,
    required this.value,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Text('Jours supplémentaires', style: context.mutedText),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIconButton(
                icon: LucideIcons.minus,
                label: 'Retirer un jour',
                bordered: true,
                onPressed: onRemove,
              ),
              const SizedBox(width: 28),
              Column(
                children: [
                  Text(value.toString(), style: context.text.figure),
                  Text(
                    value > 1 ? 'jours' : 'jour',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 28),
              AppIconButton(
                icon: LucideIcons.plus,
                label: 'Ajouter un jour',
                bordered: true,
                onPressed: onAdd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
