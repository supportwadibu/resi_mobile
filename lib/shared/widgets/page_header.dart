import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/resi_tokens.dart';

/// En-tête d'un onglet racine, miroir de `PageHeader` du backoffice : titre
/// 24/600, description en texte secondaire, actions à droite. Les écrans
/// empilés prennent `AppTopBar` à la place.
class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.description,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12),
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.headlineSmall),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: context.text.bodyMedium!.copyWith(
                      color: context.tokens.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 12),
            Wrap(spacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

/// Titre d'un groupe de contenu dans une page qui défile (« Mes biens »),
/// avec une action discrète à droite (« Voir tout »).
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    required this.title,
    this.actionLabel,
    this.onAction,
    this.icon,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: t.muted),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(title, style: context.text.titleMedium)),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: t.muted,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(actionLabel!),
                  const SizedBox(width: 2),
                  const Icon(LucideIcons.chevronRight, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Bloc bordé, fond de surface. Remplace les cartes à ombre : c'est le filet
/// qui sépare, pas la profondeur.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Fond d'appoint, réservé à une pastille d'accent (`accentSoft`).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: color ?? t.surface,
      shape: AppRadius.outlined(AppRadius.md, t.border),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Bloc titré d'une fiche, miroir de `Section` : en-tête séparé par un filet,
/// icône de section en texte secondaire, actions à droite.
class Section extends StatelessWidget {
  const Section({
    required this.title,
    required this.child,
    this.icon,
    this.actions = const [],
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final List<Widget> actions;

  /// Marge du contenu. `EdgeInsets.zero` pour une liste à filets pleine
  /// largeur.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      // Détouré : une ligne pleine largeur du contenu (liste à filets, ondulation
      // d'un appui) déborderait sinon des coins arrondis.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: t.muted),
                  const SizedBox(width: 8),
                ],
                Expanded(child: Text(title, style: context.text.titleMedium)),
                ...actions,
              ],
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Paires libellé / valeur d'une fiche, miroir de `DetailList`. Une valeur
/// absente s'affiche « — » plutôt que de laisser un trou.
class DetailList extends StatelessWidget {
  const DetailList({required this.items, super.key});

  final List<DetailItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          DetailRow(item: items[i]),
        ],
      ],
    );
  }
}

class DetailItem {
  const DetailItem(this.label, this.value, {this.valueWidget, this.icon});

  final String label;
  final String? value;

  /// Valeur riche (badge, lien) à la place du texte.
  final Widget? valueWidget;
  final IconData? icon;
}

class DetailRow extends StatelessWidget {
  const DetailRow({required this.item, super.key});

  final DetailItem item;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final value = item.value;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.icon != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(item.icon, size: 16, color: t.muted),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 2,
          child: Text(
            item.label,
            style: context.text.bodyMedium!.copyWith(color: t.muted),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child:
                item.valueWidget ??
                Text(
                  value == null || value.isEmpty ? '—' : value,
                  textAlign: TextAlign.right,
                  style: context.text.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

/// Pastille d'une icône, fond d'accent doux et ton plein posé dessus.
/// `neutral` : filet et fond de page, comme `EmptyState`.
class IconChip extends StatelessWidget {
  const IconChip({
    required this.icon,
    this.accent = AppAccent.neutral,
    this.size = 36,
    super.key,
  });

  final IconData icon;
  final AppAccent accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final neutral = accent == AppAccent.neutral;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.accentSoft(accent),
        border: neutral ? Border.all(color: t.border) : null,
        borderRadius: AppRadius.sm,
      ),
      child: Icon(
        icon,
        size: size * 0.45,
        color: neutral ? t.muted : t.accent(accent),
      ),
    );
  }
}
