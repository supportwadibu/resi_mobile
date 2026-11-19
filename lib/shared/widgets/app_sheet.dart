import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/resi_tokens.dart';
import 'app_icon_button.dart';

/// Ouvre une feuille du bas à l'allure commune : grands coins hauts, poignée,
/// fond de surface (voir `bottomSheetTheme`). La hauteur suit le contenu et
/// s'arrête sous la barre d'état.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool useRootNavigator = false,
}) {
  // Lue sur la vue elle-même : un `Scaffold` comme la feuille retirent la
  // marge système de leur contexte, où la barre vaudrait zéro.
  final navigationBar = MediaQueryData.fromView(
    View.of(context),
  ).viewPadding.bottom;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    useRootNavigator: useRootNavigator,
    // Marge basse commune à toutes les feuilles : la barre de navigation
    // d'Android (l'écran est bord à bord) plus 16. Sans elle, la dernière
    // ligne passait sous la barre et restait invisible. Le contenu
    // d'`AppSheet` défile au-delà de la hauteur de l'écran, si bien qu'un
    // texte agrandi reste entièrement atteignable.
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: navigationBar + 16),
      child: builder(sheetContext),
    ),
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
    this.action,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 20),
    super.key,
  });

  final String title;
  final String? description;
  final Widget child;

  /// Actions en bas de feuille, hors de la zone qui défile.
  final Widget? footer;
  final bool showClose;

  /// Action d'en-tête (« Réinitialiser »), à la place de la croix.
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Le titre défile avec le contenu : avec un texte agrandi, un titre
          // fixe prenait presque toute la hauteur et la zone qui défile ne
          // montrait plus une seule ligne entière.
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSheetHeader(
                    title: title,
                    description: description,
                    showClose: showClose,
                    action: action,
                  ),
                  Padding(padding: padding, child: child),
                ],
              ),
            ),
          ),
          if (footer != null)
            // La marge de la barre de navigation est déjà posée par
            // `showAppSheet`.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
              child: footer,
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
    this.action,
    super.key,
  });

  final String title;
  final String? description;
  final bool showClose;

  /// Remplace la croix : la feuille se ferme alors en glissant ou par son
  /// bouton principal.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final closable = showClose && action == null;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 4, closable ? 16 : 24, 18),
      child: Row(
        crossAxisAlignment: action == null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.text.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(description!, style: context.mutedText),
                ],
              ],
            ),
          ),
          if (action != null)
            action!
          else if (showClose)
            AppIconButton(
              icon: LucideIcons.x,
              label: 'common.close'.tr(),
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
    // Tuile arrondie sur le fond de page, comme les lignes des maquettes.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: t.background,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.5 : 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: danger ? t.dangerSurface : t.surface,
                      shape: BoxShape.circle,
                    ),
                    child:
                        iconWidget ??
                        Icon(
                          icon,
                          size: 18,
                          color: danger ? t.danger : t.foreground,
                        ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: context.text.titleSmall!.copyWith(
                            color: color,
                          ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 2),
                          Text(description!, style: context.text.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(LucideIcons.arrowUpRight, size: 16, color: t.muted),
                ],
              ),
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
