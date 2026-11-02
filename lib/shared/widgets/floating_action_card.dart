import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/resi_tokens.dart';
import 'app_sheet.dart';
import 'frosted_surface.dart';

/// Création proposée par la carte flottante.
class FloatingFeature {
  const FloatingFeature({
    required this.icon,
    required this.label,
    required this.action,
    this.description,
  });

  final IconData icon;
  final String label;
  final String? description;
  final String action;
}

/// Carte des créations, ouverte au-dessus du bouton « Créer ». Les lignes
/// sont celles des feuilles de choix (`AppSheetAction`), séparées d'un filet.
class FloatingActionCard extends StatelessWidget {
  const FloatingActionCard({
    required this.features,
    required this.onSelect,
    super.key,
  });

  final List<FloatingFeature> features;
  final void Function(String action) onSelect;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: FrostedSurface(
        opacity: 0.85,
        borderRadius: FrostedSurface.card,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final feature in features) ...[
                if (feature != features.first)
                  Divider(height: 1, color: context.tokens.border),
                AppSheetAction(
                  icon: feature.icon,
                  label: feature.label.tr(),
                  description: feature.description?.tr(),
                  onTap: () => onSelect(feature.action),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
