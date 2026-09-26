import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_picker_field.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTimeRange> onPicked;

  const CustomDatePicker({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onPicked,
  });

  String _format(DateTime? date) {
    if (date == null) return 'Sélectionner';
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  Future<void> _pick(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );
    if (range != null) onPicked(range);
  }

  @override
  Widget build(BuildContext context) {
    return AppPickerField(
      value: startDate == null ? null : '${_format(startDate)}  →  ${_format(endDate)}',
      placeholder: 'Choisir les dates',
      icon: LucideIcons.calendarRange,
      onTap: () => _pick(context),
    );
  }
}
