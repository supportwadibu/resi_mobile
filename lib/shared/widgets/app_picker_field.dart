import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/resi_tokens.dart';

/// Champ qui ouvre un sélecteur (date, période, liste) au lieu d'une saisie :
/// même cadre qu'un champ texte, valeur à gauche, chevron à droite.
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    required this.onTap,
    this.value,
    this.placeholder,
    this.label,
    this.icon,
    this.onClear,
    super.key,
  });

  /// Valeur choisie ; `null` affiche [placeholder] en texte secondaire.
  final String? value;
  final String? placeholder;
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Croix d'effacement, quand une valeur est posée et peut être retirée.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasValue = value != null && value!.isNotEmpty;
    final field = Material(
      color: t.background,
      shape: AppRadius.outlined(AppRadius.md, t.border),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: t.muted),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  hasValue ? value! : placeholder ?? 'common.choose'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: hasValue ? context.text.bodyMedium : context.mutedText,
                ),
              ),
              if (hasValue && onClear != null)
                InkWell(
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(LucideIcons.x, size: 16, color: t.muted),
                  ),
                )
              else
                Icon(LucideIcons.chevronDown, size: 16, color: t.muted),
            ],
          ),
        ),
      ),
    );
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label!, style: context.text.titleSmall),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
