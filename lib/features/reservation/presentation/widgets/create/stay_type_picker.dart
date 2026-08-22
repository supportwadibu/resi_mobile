import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: StayType.values.map((type) {
          final active = type == selected;
          final isLast = type == StayType.values.last;

          return Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: GestureDetector(
              onTap: () => onSelected(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary.withValues(alpha: 0.06)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.grey200,
                    width: active ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color: active
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (dailyPrice > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        _priceLabel(type),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
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
