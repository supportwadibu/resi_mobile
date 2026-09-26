import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_picker_field.dart';

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
    // Un champ figé (entrée d'un check-in) reste lisible mais s'estompe,
    // comme un bouton désactivé.
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: AppPickerField(
        value: value == null ? null : _format(value!),
        placeholder: hint,
        icon: LucideIcons.calendar,
        onTap: enabled ? () => _pick(context) : null,
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
