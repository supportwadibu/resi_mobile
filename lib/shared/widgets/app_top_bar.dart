import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'app_icon_button.dart';

/// Barre des écrans empilés : retour `chevronLeft`, titre aligné à gauche,
/// filet bas (voir `appBarTheme`). Les onglets racines prennent `PageHeader`.
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

  @override
  Size get preferredSize =>
      Size.fromHeight(56 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && (onBack != null || Navigator.of(context).canPop());
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: canPop ? 0 : 16,
      leading: canPop
          ? AppIconButton(
              icon: LucideIcons.chevronLeft,
              label: 'Retour',
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [...actions, const SizedBox(width: 8)],
      bottom: bottom,
    );
  }
}
