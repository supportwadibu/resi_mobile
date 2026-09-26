import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';

/// Barre de l'écran financier, avec le choix du périmètre (tout le parc ou
/// une résidence).
class FinanceAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FinanceAppBar({super.key, this.onFilterTap, this.scopeLabel});

  final VoidCallback? onFilterTap;

  /// Résidence retenue, `null` pour tout le parc.
  final String? scopeLabel;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
      title: 'Finances',
      actions: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: AppButton(
            label: scopeLabel ?? 'Tout le parc',
            icon: LucideIcons.slidersHorizontal,
            // Périmètre restreint : le bouton passe en noir, pour qu'on lise
            // que les chiffres ne couvrent pas tout le parc.
            variant: scopeLabel == null
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary,
            size: AppButtonSize.sm,
            onPressed: onFilterTap,
          ),
        ),
      ],
    );
  }
}
