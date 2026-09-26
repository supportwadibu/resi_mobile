import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';
import 'page_header.dart';

/// Couleur de la note d'une tuile : évolution ou point d'attention.
enum StatNoteTone { up, down, attention }

/// Chiffre clé, avec son icône et une note de contexte — miroir de
/// `StatTile` du backoffice.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppAccent.neutral,
    this.note,
    this.noteTone,
    this.onTap,
    this.compact = false,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  /// Tuile étroite, trois par ligne : l'icône passe en petit à côté du
  /// libellé et le chiffre perd une taille.
  final bool compact;

  /// Couleur de la pastille d'icône.
  final AppAccent accent;
  final String? note;
  final StatNoteTone? noteTone;

  /// Rend la tuile cliquable, vers la liste détaillée.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final noteColor = switch (noteTone) {
      StatNoteTone.up => t.accentGreen,
      StatNoteTone.down => t.accentRed,
      StatNoteTone.attention => t.accentAmber,
      null => t.muted,
    };
    if (compact) {
      return AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: accent == AppAccent.neutral
                      ? t.muted
                      : t.accent(accent),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: context.text.figure.copyWith(fontSize: 20),
              ),
            ),
          ],
        ),
      );
    }
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium!.copyWith(color: t.muted),
                ),
              ),
              const SizedBox(width: 8),
              IconChip(icon: icon, accent: accent),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, maxLines: 1, style: context.text.figure),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(
              note!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall!.copyWith(color: noteColor),
            ),
          ],
        ],
      ),
    );
  }
}

/// Grille de tuiles, deux colonnes de même hauteur.
class StatGrid extends StatelessWidget {
  const StatGrid({required this.children, this.spacing = 12, super.key});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              SizedBox(width: spacing),
              Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class BreakdownRow {
  const BreakdownRow({
    required this.label,
    required this.count,
    this.tone,
    this.display,
    this.onTap,
  });

  final String label;
  final num count;

  /// Ton de la jauge, pour une répartition par statut. Sans, la jauge reste
  /// en noir et blanc — une couleur d'accent y serait lue comme un statut.
  final AppAccent? tone;

  /// Valeur affichée à droite, si elle diffère du compte (un montant).
  final String? display;
  final VoidCallback? onTap;
}

/// Répartition d'un total par catégorie, miroir de `Breakdown`. La longueur
/// de la jauge porte l'information.
class Breakdown extends StatelessWidget {
  const Breakdown({
    required this.title,
    required this.rows,
    this.icon,
    super.key,
  });

  final String title;
  final IconData? icon;
  final List<BreakdownRow> rows;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final total = rows.fold<num>(0, (sum, row) => sum + row.count);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: t.muted),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in rows)
            InkWell(
              onTap: row.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(row.label, style: context.text.bodyMedium),
                        ),
                        Text(
                          row.display ?? '${row.count}',
                          style: context.text.bodyMedium!.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 4,
                      child: LayoutBuilder(
                        builder: (context, box) => Stack(
                          children: [
                            Container(color: t.background),
                            Container(
                              width: total > 0
                                  ? box.maxWidth * (row.count / total)
                                  : 0,
                              color: row.tone == null
                                  ? t.primary
                                  : row.tone == AppAccent.neutral
                                  ? t.muted
                                  : t.accent(row.tone!),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
