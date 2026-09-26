import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';

import '../../../data/models/reservation_model.dart';

/// Choix du type de séjour, avec le tarif correspondant.
///
/// Le passage et la demi-journée sont infra-journaliers : les afficher avec
/// leur prix évite au propriétaire de calculer la fraction de tête.
class StayTypePicker extends StatelessWidget {
  const StayTypePicker({
    required this.selected,
    required this.dailyPrice,
    required this.onSelected,
    super.key,
  });

  final StayType selected;

  /// Tarif journalier du bien, `0` tant qu'aucun bien n'est choisi.
  final double dailyPrice;

  final ValueChanged<StayType> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Trois options de même largeur : le tarif de chacune se compare d'un
    // coup d'œil, sans défilement.
    return Row(
      children: [
        for (final type in StayType.values) ...[
          if (type != StayType.values.first) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              selected: type == selected,
              button: true,
              child: Material(
                color: type == selected ? t.background : t.surface,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: type == selected ? t.primary : t.border,
                    width: type == selected ? 1.5 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => onSelected(type),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall!.copyWith(
                            fontWeight: type == selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        if (dailyPrice > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            _priceLabel(type),
                            style: context.text.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Reprend les ratios du serveur : demi-journée à 50 %, passage à 30 %.
  String _priceLabel(StayType type) {
    final price = switch (type) {
      StayType.fullDay => dailyPrice,
      StayType.halfDay => (dailyPrice * 0.5).roundToDouble(),
      StayType.passage => (dailyPrice * 0.3).roundToDouble(),
    };

    return '${_thousands(price)} F';
  }

  /// Sépare les milliers par une espace insécable, comme ailleurs dans l'app.
  static String _thousands(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }
}
