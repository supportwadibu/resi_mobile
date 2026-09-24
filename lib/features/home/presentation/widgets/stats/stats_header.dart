import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class StatsHeader extends StatelessWidget {
  const StatsHeader({
    super.key,
    required this.from,
    required this.to,
    required this.onPeriodPicked,
  });

  /// Bornes du relevé affiché, reprises telles quelles dans le titre : le
  /// libellé doit décrire la période des chiffres, pas le mois courant.
  final DateTime from;
  final DateTime to;

  final ValueChanged<DateTimeRange> onPeriodPicked;

  static const _months = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  /// « Septembre 2026 » quand la période tient dans un mois, « 03/09 - 21/10 »
  /// sinon : le nom du mois devient trompeur dès que la fenêtre le déborde.
  String get _label {
    if (from.year == to.year && from.month == to.month) {
      return '${_months[from.month - 1]} ${from.year}';
    }

    String short(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return '${short(from)} - ${short(to)}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: () async {
            final DateTimeRange? picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              initialDateRange: DateTimeRange(start: from, end: to),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) onPeriodPicked(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                SizedBox(width: 6),
                Text(
                  'Filtrer',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
