import 'package:flutter/material.dart';
import '../../../../../core/theme/app_text_styles.dart';
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
              color: category.color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.label, style: AppTextStyles.labelSmall),
            const SizedBox(height: 2),
            Text(
              CurrencyFormatter.format(category.amount),
              style: AppTextStyles.valueSmall,
            ),
          ],
        ),
      ],
    );
  }
}
