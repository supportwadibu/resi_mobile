import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';

/// Caractéristiques marquantes du bien, en pastilles bordées.
class PropertyFeatures extends StatelessWidget {
  const PropertyFeatures({super.key, required this.features});

  final List<PropertyFeature> features;

  @override
  Widget build(BuildContext context) {
    if (features.isEmpty) return const SizedBox.shrink();
    final t = context.tokens;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final feature in features)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: AppRadius.pill,
                border: Border.all(color: t.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(feature.icon, size: 16, color: t.foreground),
                  const SizedBox(width: 8),
                  Text(
                    // Un équipement (wifi, piscine) n'a pas de nombre : « 1
                    // Wifi » ne dirait rien de plus que « Wifi ».
                    feature.count > 1 || feature.countable
                        ? '${feature.count} ${feature.label}'
                        : feature.label,
                    style: context.text.labelLarge,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PropertyFeature {
  const PropertyFeature({
    required this.icon,
    required this.label,
    required this.count,
    this.countable = true,
  });

  final IconData icon;
  final String label;
  final int count;

  /// Faux pour un équipement présent ou absent, sans quantité.
  final bool countable;
}
