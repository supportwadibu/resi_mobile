import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';

/// Barre des écrans empilés, d'après les maquettes : bouton retour rond et
/// actions sur la première ligne, grand titre aligné à gauche dessous. Pas
/// de filet : le titre sépare. Les onglets racines prennent `PageHeader`.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    required this.title,
    this.actions = const [],
    this.onBack,
    this.showBack = true,
    this.bottom,
    super.key,
  });

  final String title;
  final List<Widget> actions;

  /// Retour personnalisé (confirmation d'abandon d'un formulaire…). Par
  /// défaut, `maybePop`.
  final VoidCallback? onBack;
  final bool showBack;
  final PreferredSizeWidget? bottom;

  static const _rowHeight = 60.0;
  static const _titleHeight = 48.0;

  @override
  Size get preferredSize => Size.fromHeight(
    _rowHeight + _titleHeight + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context) {
    final canPop =
        showBack && (onBack != null || Navigator.of(context).canPop());
    // Transparente : la barre laisse voir le fond de l'écran, quel qu'il
    // soit, si bien que l'encoche et le contenu partagent la même couleur.
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: _rowHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (canPop)
                      RoundBackButton(
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
                      ),
                    const Spacer(),
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(
              height: _titleHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.displaySmall!.copyWith(fontSize: 28),
                  ),
                ),
              ),
            ),
            ?bottom,
          ],
        ),
      ),
    );
  }
}

/// Bouton retour des maquettes : disque bordé, chevron.
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      button: true,
      label: 'common.back'.tr(),
      child: Material(
        color: t.surface,
        shape: CircleBorder(side: BorderSide(color: t.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox.square(
            dimension: 44,
            child: Icon(LucideIcons.chevronLeft, size: 20),
          ),
        ),
      ),
    );
  }
}
