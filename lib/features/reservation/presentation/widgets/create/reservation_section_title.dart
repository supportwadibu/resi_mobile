import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';

class ReservationSectionTitle extends StatelessWidget {
  const ReservationSectionTitle({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: context.text.titleMedium),
    );
  }
}
