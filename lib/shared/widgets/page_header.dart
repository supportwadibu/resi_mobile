import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';
import '../motion/motion.dart';

/// En-tête d'un onglet racine, d'après les maquettes : grand titre aligné à
/// gauche, description en dessous, actions à droite sur la même ligne. Les
/// écrans empilés prennent `AppTopBar`.
class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.description,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(24, 12, 24, 16),
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
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.displayMedium!.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(description!, style: context.mutedText),
                ],
              ],
            ),
          ),
          for (final action in actions) ...[const SizedBox(width: 8), action],
        ],
      ),
    );
  }
}

/// Titre d'un groupe de contenu dans une page qui défile, avec son action
/// en pilule à droite (« Voir tout »).
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
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.text.titleLarge!.copyWith(fontSize: 20),
            ),
          ),
          if (actionLabel != null && onAction != null)
            Material(
              color: t.surface,
              shape: StadiumBorder(side: BorderSide(color: t.border)),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(actionLabel!, style: context.text.labelMedium),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.arrowUpRight, size: 14),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Carte des maquettes : surface arrondie (`lg`), liseré clair. Une carte
/// qui s'ouvre se tasse sous le doigt.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Fond d'appoint : un accent de surface (`lavender`, `sand`) ou une
  /// pastille douce.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final card = Material(
      color: color ?? t.surface,
      shape: AppRadius.outlined(AppRadius.lg, color ?? t.border),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    return onTap == null ? card : PressScale(scale: 0.98, child: card);
  }
}

/// Bloc titré d'une fiche : carte arrondie, titre et pastille d'icône en
/// tête, sans filet — l'espace sépare, comme sur les maquettes.
class Section extends StatelessWidget {
  const Section({
    required this.title,
    required this.child,
    this.icon,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    super.key,
  });

  final String title;
  final Widget child;
  final IconData? icon;
  final List<Widget> actions;

  /// Marge du contenu. `EdgeInsets.zero` pour une liste pleine largeur.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      // Détouré : une ligne pleine largeur du contenu (ondulation d'un appui)
      // déborderait sinon des coins arrondis.
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border.all(color: t.border),
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  IconChip(icon: icon!, size: 34),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: context.text.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
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

/// Paires libellé / valeur d'une fiche : le libellé en petit au-dessus de
/// la valeur, l'icône sur un disque. Une valeur absente s'affiche « — ».
class DetailList extends StatelessWidget {
  const DetailList({required this.items, super.key});

  final List<DetailItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
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
    final value = item.value;
    return Row(
      children: [
        if (item.icon != null) ...[
          IconChip(icon: item.icon!, size: 40),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: context.text.bodySmall),
              const SizedBox(height: 2),
              item.valueWidget ??
                  Text(
                    value == null || value.isEmpty ? '—' : value,
                    style: context.text.titleSmall,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Pastille ronde d'une icône, fond d'accent doux et ton plein posé dessus.
/// `neutral` : fond de page, icône à la couleur du texte.
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
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size * 0.44,
        color: neutral ? t.foreground : t.accent(accent),
      ),
    );
  }
}
