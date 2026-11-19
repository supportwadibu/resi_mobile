import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_picker_field.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';

/// Bien auquel imputer la dépense.
///
/// La valeur portée est l'identifiant, pas le libellé : deux biens peuvent
/// partager un nom, et c'est l'identifiant qu'attend l'API.
class ResidenceOption {
  const ResidenceOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// Champ de choix d'un bien ou d'une résidence : il ouvre une feuille du bas
/// qui liste les options en tuiles, la retenue cochée. Remplace la liste
/// déroulante, que les maquettes n'emploient nulle part.
class ResidenceDropdown extends StatelessWidget {
  final String? value;
  final List<ResidenceOption> residences;
  final ValueChanged<String?> onChanged;
  final String? hint;

  const ResidenceDropdown({
    super.key,
    required this.value,
    required this.residences,
    required this.onChanged,
    this.hint,
  });

  Future<void> _pick(BuildContext context) async {
    if (residences.isEmpty) return;
    final title = hint ?? 'expense.choose_property_hint'.tr();
    final picked = await showAppSheet<String>(
      context: context,
      builder: (sheet) => AppSheet(
        title: title,
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            for (final option in residences)
              AppSheetAction(
                icon: LucideIcons.building2,
                label: option.label,
                trailing: option.id == value
                    ? Icon(
                        LucideIcons.circleCheck,
                        size: 20,
                        color: context.tokens.foreground,
                      )
                    : const SizedBox.shrink(),
                onTap: () => Navigator.of(sheet).pop(option.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    String? label;
    for (final option in residences) {
      if (option.id == value) label = option.label;
    }
    return AppPickerField(
      value: label,
      placeholder: hint ?? 'expense.choose_property_hint'.tr(),
      icon: LucideIcons.building2,
      onTap: () => _pick(context),
    );
  }
}
