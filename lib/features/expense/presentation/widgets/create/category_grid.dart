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
      // Quatre colonnes : les huit catégories tiennent alors en deux rangées
      // visibles d'un coup, là où trois colonnes en imposaient trois et
      // repoussaient la date sous la ligne de flottaison.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.92,
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
