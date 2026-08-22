import 'package:flutter/material.dart';
import '../../../data/models/expense_category_model.dart';
import 'expense_legend_item.dart';

class ExpenseLegendGrid extends StatelessWidget {
  final List<ExpenseCategoryModel> categories;

  const ExpenseLegendGrid({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    // 2 colonnes, N/2 lignes
    final rows = <Widget>[];
    for (int i = 0; i < categories.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: ExpenseLegendItem(category: categories[i])),
            if (i + 1 < categories.length)
              Expanded(child: ExpenseLegendItem(category: categories[i + 1])),
          ],
        ),
      );
      if (i + 2 < categories.length) rows.add(const SizedBox(height: 14));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}
