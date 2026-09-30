import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';

import '../../business_logic/gerant_scope_cubit.dart';

/// Sélecteur de périmètre : résidences dépliables, logements cochables.
///
/// Partagé par la création et la modification du périmètre — le geste est le
/// même, et deux copies divergeraient au premier ajustement.
///
/// Cocher une résidence coche ses logements, mais aucun identifiant de
/// résidence n'en sort : ce que l'application transmet reste toujours une liste
/// de logements, le serveur ignorant les résidences.
class ScopeSelector extends StatelessWidget {
  const ScopeSelector({
    super.key,
    required this.groups,
    required this.standalone,
    required this.selection,
    required this.onToggleResidence,
    required this.onToggleProperty,
  });

  final List<ResidenceGroup> groups;
  final List<PropertyOption> standalone;
  final Set<String> selection;
  final void Function(ResidenceSelection) onToggleResidence;
  final void Function(String) onToggleProperty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          _ResidenceTile(
            group: group,
            selection: selection,
            onToggleResidence: onToggleResidence,
            onToggleProperty: onToggleProperty,
          ),
          const SizedBox(height: 10),
        ],
        if (standalone.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(4, 6, 4, 10),
            child: Text(
              'Logements hors résidence',
              style: context.text.labelMedium!.copyWith(
                color: context.tokens.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.tokens.surface,
              border: Border.all(color: context.tokens.border),
              borderRadius: AppRadius.md,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final property in standalone)
                  _PropertyRow(
                    label: property.label,
                    checked: selection.contains(property.id),
                    onChanged: () => onToggleProperty(property.id),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Une résidence et ses logements, repliée par défaut.
///
/// Repliée : un parc de plusieurs résidences dépasserait sinon plusieurs écrans
/// avant même que le propriétaire voie ce qu'il y a à cocher.
class _ResidenceTile extends StatefulWidget {
  const _ResidenceTile({
    required this.group,
    required this.selection,
    required this.onToggleResidence,
    required this.onToggleProperty,
  });

  final ResidenceGroup group;
  final Set<String> selection;
  final void Function(ResidenceSelection) onToggleResidence;
  final void Function(String) onToggleProperty;

  @override
  State<_ResidenceTile> createState() => _ResidenceTileState();
}

class _ResidenceTileState extends State<_ResidenceTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ids = widget.group.residence.propertyIds;
    final checkedCount = ids.where(widget.selection.contains).length;
    final checkboxValue = residenceCheckboxValue(
      checkedCount: checkedCount,
      totalCount: ids.length,
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.tokens.surface,
        border: Border.all(color: context.tokens.border),
        borderRadius: AppRadius.md,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  // La case coche la résidence entière ; le reste de la ligne
                  // la déplie. Deux gestes distincts sur la même ligne, pour
                  // que confier tout un immeuble ne demande pas d'abord de
                  // l'ouvrir.
                  Checkbox(
                    // `null` — et non `false` — quand une partie seulement est
                    // confiée : Flutter ne dessine le tiret de l'état mixte que
                    // sur une valeur nulle. Un `bool` rendait six logements sur
                    // dix visuellement identiques à zéro sur dix, soit
                    // exactement le cas que le propriétaire rencontre.
                    value: checkboxValue,
                    tristate: true,
                    onChanged: (_) =>
                        widget.onToggleResidence(widget.group.residence),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.residence.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$checkedCount confié${checkedCount > 1 ? 's' : ''} '
                          'sur ${ids.length}',
                          style: context.text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 20,
                    color: context.tokens.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: context.tokens.border),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                children: [
                  for (final property in widget.group.properties)
                    _PropertyRow(
                      label: property.label,
                      checked: widget.selection.contains(property.id),
                      onChanged: () => widget.onToggleProperty(property.id),
                      indented: true,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Un logement cochable.
class _PropertyRow extends StatelessWidget {
  const _PropertyRow({
    required this.label,
    required this.checked,
    required this.onChanged,
    this.indented = false,
  });

  final String label;
  final bool checked;
  final VoidCallback onChanged;
  final bool indented;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      child: Padding(
        padding: EdgeInsets.fromLTRB(indented ? 20 : 8, 2, 12, 2),
        child: Row(
          children: [
            Checkbox(value: checked, onChanged: (_) => onChanged()),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
