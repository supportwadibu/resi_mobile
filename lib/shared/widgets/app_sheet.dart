import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/resi_tokens.dart';
import 'app_icon_button.dart';

/// Ouvre une feuille du bas à l'allure commune : angles droits, poignée,
/// fond de surface (voir `bottomSheetTheme`). La hauteur suit le contenu et
/// s'arrête sous la barre d'état.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool useRootNavigator = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    useRootNavigator: useRootNavigator,
    builder: builder,
  );
}

/// Contenu type d'une feuille : en-tête (titre, description, fermeture),
/// corps défilant, pied d'actions séparé par un filet. Le clavier repousse
/// le tout plutôt que de masquer les champs.
class AppSheet extends StatelessWidget {
  const AppSheet({
    required this.title,
    required this.child,
    this.description,
    this.footer,
    this.showClose = true,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    super.key,
  });

  final String title;
  final String? description;
  final Widget child;

  /// Actions en bas de feuille, hors de la zone qui défile.
  final Widget? footer;
  final bool showClose;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(
            title: title,
            description: description,
            showClose: showClose,
          ),
          Flexible(
            child: SingleChildScrollView(padding: padding, child: child),
          ),
          if (footer != null)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: footer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// En-tête d'une feuille : titre 18/600, description, bouton de fermeture.
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({
    required this.title,
    this.description,
    this.showClose = true,
    super.key,
  });

  final String title;
  final String? description;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, showClose ? 8 : 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleLarge),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(description!, style: context.mutedText),
                ],
              ],
            ),
          ),
          if (showClose)
            AppIconButton(
              icon: LucideIcons.x,
              label: 'Fermer',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
        ],
      ),
    );
  }
}

/// Ligne d'action d'une feuille de choix : icône sur pastille, libellé,
/// description. Remplace les tuiles arrondies des anciens menus.
class AppSheetAction extends StatelessWidget {
  const AppSheetAction({
    required this.label,
    required this.onTap,
    this.icon,
    this.iconWidget,
    this.description,
    this.danger = false,
    this.trailing,
    super.key,
  }) : assert(icon != null || iconWidget != null, 'icon ou iconWidget');

  final IconData? icon;

  /// Icône qui n'est pas une `IconData` : logo de marque (WhatsApp), SVG.
  final Widget? iconWidget;
  final String label;
  final String? description;
  final VoidCallback? onTap;
  final bool danger;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = danger ? t.danger : t.foreground;
    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: danger ? t.dangerSurface : t.background,
                  border: danger ? null : Border.all(color: t.border),
                  borderRadius: AppRadius.sm,
                ),
                child:
                    iconWidget ??
                    Icon(icon, size: 16, color: danger ? t.danger : t.muted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: context.text.titleSmall!.copyWith(color: color),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(description!, style: context.text.bodySmall),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(LucideIcons.chevronRight, size: 16, color: t.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Puce de choix en pilule : noire (primary) une fois choisie, bordée sinon.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.primaryForeground : t.foreground;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? t.primary : t.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? t.primary : t.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: selected ? fg : t.muted),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: context.text.labelLarge!.copyWith(color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
