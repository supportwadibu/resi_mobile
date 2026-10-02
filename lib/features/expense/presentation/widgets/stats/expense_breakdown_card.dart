import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
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
    return Section(
      title: 'expense.breakdown'.tr(),
      icon: LucideIcons.chartPie,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: DonutChart(
              categories: categories,
              size: 180,
              strokeWidth: 32,
            ),
          ),
          const SizedBox(height: 20),
          ExpenseLegendGrid(categories: categories),
          const SizedBox(height: 16),
          ExportButton(onTap: onExport),
        ],
      ),
    );
  }
}
