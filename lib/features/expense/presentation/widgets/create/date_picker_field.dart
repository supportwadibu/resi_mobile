import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_picker_field.dart';

class DatePickerField extends StatelessWidget {
  final String date;
  final VoidCallback onTap;

  const DatePickerField({super.key, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPickerField(
      value: date,
      icon: LucideIcons.calendar,
      onTap: onTap,
    );
  }
}
