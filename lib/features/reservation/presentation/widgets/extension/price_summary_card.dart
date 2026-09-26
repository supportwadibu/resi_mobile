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
          _row(context, 'Coût par jour', pricePerDay),
          const SizedBox(height: 8),
          _row(
            context,
            days > 1 ? 'Sous-total ($days jours)' : 'Sous-total (1 jour)',
            subtotal,
          ),
          if (discountPercent > 0) ...[
            const SizedBox(height: 8),
            _row(context, 'Remise durée', '-$discountPercent %'),
          ],
          const Divider(height: 24),
          Row(
            children: [
              Text(
                'Total à payer',
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
