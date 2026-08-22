import 'package:flutter/material.dart';
import '../../../data/models/expense_model.dart';
import 'category_item.dart';

class CategoryGrid extends StatelessWidget {
  final List<ExpenseCategory> categories;
  final ExpenseCategory? selected;
  final Function(ExpenseCategory) onSelected;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      itemCount: categories.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (_, index) {
        final category = categories[index];

        return CategoryItem(
          category: category,
          selected: selected == category,
          onTap: () => onSelected(category),
        );
      },
    );
  }
}
