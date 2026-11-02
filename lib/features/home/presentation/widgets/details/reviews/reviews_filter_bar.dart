import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';

class ReviewsFilterBar extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const ReviewsFilterBar({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;

          return AppChoiceChip(
            label: filter,
            selected: isSelected,
            onTap: () => onFilterChanged(filter),
          );
        },
      ),
    );
  }
}
