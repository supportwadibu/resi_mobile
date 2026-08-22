import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

/// Champ de date et d'heure qui remonte sa valeur au formulaire.
///
/// Distinct de `DateField`, qui garde sa valeur pour lui : ici l'entrée et la
/// sortie commandent le montant et le contrôle de chevauchement, elles doivent
/// donc remonter.
class DateTimeField extends StatelessWidget {
  const DateTimeField({
    required this.value,
    required this.onChanged,
    this.hint = 'jj/mm/aaaa — --:--',
    this.enabled = true,
    this.firstDate,
    super.key,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String hint;

  /// Un check-in fixe l'entrée à l'instant présent : le champ s'affiche mais
  /// ne s'ouvre pas.
  final bool enabled;

  /// Borne basse du calendrier. Une réservation future ne se prend pas dans le
  /// passé ; une sortie ne précède pas son entrée.
  final DateTime? firstDate;

  @override
  Widget build(BuildContext context) {
    final label = value == null ? hint : _format(value!);

    return GestureDetector(
      onTap: enabled ? () => _pick(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface : AppColors.grey200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: value == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: enabled ? AppColors.grey500 : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final lower = firstDate ?? now.subtract(const Duration(days: 365));
    final initial = value ?? (lower.isAfter(now) ? lower : now);

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: lower,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  static String _format(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} — $hour:$minute';
  }
}
