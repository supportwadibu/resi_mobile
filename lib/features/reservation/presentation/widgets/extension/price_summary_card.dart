import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF4F4F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row("Coût par jour", pricePerDay),
          const SizedBox(height: 12),
          _row(days > 1 ? "Sous-total ($days jours)" : "Sous-total (1 jour)", subtotal),
          if (discountPercent > 0) ...[
            const SizedBox(height: 12),
            _row("Remise durée", "-$discountPercent %"),
          ],
          const Divider(height: 28),
          _row("Total à payer", total, isTotal: true),
        ],
      ),
    );
  }

  Widget _row(String title, String value, {bool isTotal = false}) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: isTotal ? const Color(0xff252B5C) : Colors.grey,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? const Color(0xff34C759) : const Color(0xff252B5C),
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 26 : 14,
          ),
        ),
      ],
    );
  }
}
