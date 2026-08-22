import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';

class FinanceSummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final TextStyle valueStyle;
  final Widget? trailing;

  const FinanceSummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.valueStyle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelMedium),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(CurrencyFormatter.format(amount), style: valueStyle),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            ],
          ),
        ],
      ),
    );
  }
}
