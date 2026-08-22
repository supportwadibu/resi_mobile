import 'package:flutter/material.dart';

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

          return FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                onFilterChanged(filter);
              }
            },
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFFEEEDFE),
            checkmarkColor: const Color(0xFF534AB7),
            labelStyle: TextStyle(
              color: isSelected
                  ? const Color(0xFF534AB7)
                  : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF534AB7)
                  : Colors.grey.shade300,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF534AB7)
                    : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }
}
