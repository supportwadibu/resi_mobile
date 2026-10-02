import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

/// Coût de la prolongation : tarif, sous-total, remise et total.
class PriceSummaryCard extends StatelessWidget {
  final String pricePerDay;

  /// Nombre de jours facturés, pour situer le sous-total.
  final int days;
  final String subtotal;
  final String total;

  /// Remise de durée appliquée, en pourcentage. `0` si aucun palier atteint.
  final int discountPercent;

  const PriceSummaryCard({
    super.key,
    required this.pricePerDay,
    required this.days,
    required this.subtotal,
    required this.total,
    this.discountPercent = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _row(context, 'stay_extension.daily_cost'.tr(), pricePerDay),
          const SizedBox(height: 8),
          _row(
            context,
            'stay_extension.subtotal'.plural(days),
            subtotal,
          ),
          if (discountPercent > 0) ...[
            const SizedBox(height: 8),
            _row(
              context,
              'stay_extension.length_discount'.tr(),
              '-$discountPercent %',
            ),
          ],
          const Divider(height: 24),
          Row(
            children: [
              Text(
                'stay_extension.total_due'.tr(),
                style: context.text.titleSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(total, style: context.text.figure),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String title, String value) {
    return Row(
      children: [
        Text(title, style: context.mutedText),
        const Spacer(),
        Text(value, style: context.text.amount),
      ],
    );
  }
}
