import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import '../../../data/models/expense_category_model.dart';
import 'donut_chart.dart';
import 'expense_legend_grid.dart';
import 'export_button.dart';

class ExpenseBreakdownCard extends StatelessWidget {
  final List<ExpenseCategoryModel> categories;
  final VoidCallback? onExport;

  const ExpenseBreakdownCard({
    super.key,
    required this.categories,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Répartition des dépenses', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 24),
          Center(
            child: DonutChart(
              categories: categories,
              size: 200,
              strokeWidth: 40,
            ),
          ),
          const SizedBox(height: 24),
          ExpenseLegendGrid(categories: categories),
          const SizedBox(height: 20),
          ExportButton(onTap: onExport),
        ],
      ),
    );
  }
}
