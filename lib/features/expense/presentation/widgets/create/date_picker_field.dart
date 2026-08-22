import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  final String date;
  final VoidCallback onTap;

  const DatePickerField({super.key, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xffF5F5FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(date),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }
}
