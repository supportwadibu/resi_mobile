import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';

/// Une option d'[AppChoiceTiles] : une icône, ou un sigle court (« FR »)
/// quand aucune icône ne dit mieux la chose.
class AppChoiceTileOption<T> {
  const AppChoiceTileOption({
    required this.value,
    required this.label,
    this.icon,
    this.glyph,
  }) : assert(icon != null || glyph != null, 'icon ou glyph');

  final T value;
  final String label;
  final IconData? icon;
  final String? glyph;
}

/// Choix exclusif en tuiles côte à côte — apparence, langue.
///
/// Remplace le `SegmentedButton` : ses segments coupaient les libellés dès
/// que le texte grossissait, et sa barre fine ne ressemblait à aucune pièce
/// des maquettes. Tuiles basses, icône et libellé sur une ligne ; la tuile
/// choisie passe en lavande — en noir, une rangée de choix faisait bloc et
/// alourdissait la feuille —, les autres restent sur le fond de page.
class AppChoiceTiles<T> extends StatelessWidget {
  const AppChoiceTiles({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<AppChoiceTileOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _ChoiceTile(
              option: options[i],
              selected: options[i].value == selected,
              onTap: () => onSelected(options[i].value),
            ),
          ),
        ],
      ],
    );
  }
}

class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppChoiceTileOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.onLavender : t.foreground;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? t.lavender : t.background,
          borderRadius: AppRadius.sm,
          border: Border.all(color: selected ? t.lavender : t.border),
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: AppRadius.smShape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (option.icon != null)
                    Icon(option.icon, size: 15, color: fg)
                  else
                    Text(
                      option.glyph!,
                      style: context.text.labelSmall!.copyWith(
                        color: selected ? fg : t.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelLarge!.copyWith(
                        color: fg,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
