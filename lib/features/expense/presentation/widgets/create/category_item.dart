import 'package:flutter/material.dart';
import '../../../data/models/expense_model.dart';

class CategoryItem extends StatelessWidget {
  final ExpenseCategory category;
  final bool selected;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? Colors.black : const Color(0xffF5F5FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              color: selected ? Colors.white : const Color(0xff1D2452),
            ),
            const SizedBox(height: 8),
            Text(
              category.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.white : const Color(0xff1D2452),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
