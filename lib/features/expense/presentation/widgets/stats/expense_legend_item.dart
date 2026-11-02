import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../data/models/expense_category_model.dart';

class ExpenseLegendItem extends StatelessWidget {
  final ExpenseCategoryModel category;

  const ExpenseLegendItem({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: category.category.colorIn(context.tokens),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.label, style: context.text.bodySmall),
            const SizedBox(height: 2),
            Text(
              CurrencyFormatter.short(category.amount),
              style: context.text.amount,
            ),
          ],
        ),
      ],
    );
  }
}
