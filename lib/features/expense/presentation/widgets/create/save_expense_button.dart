import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';

/// Barre d'enregistrement de la dépense, ancrée en bas de l'écran.
class SaveExpenseButton extends StatelessWidget {
  /// `null` désactive le bouton — pendant l'envoi, par exemple.
  final VoidCallback? onPressed;

  /// Libellé de remplacement, pour distinguer création et modification.
  final String? label;

  /// Envoi en cours : le bouton montre un indicateur à la place du libellé.
  ///
  /// Passé explicitement plutôt que déduit du libellé : une comparaison de
  /// chaîne ferait disparaître l'indicateur au premier remaniement du texte,
  /// sans rien signaler.
  final bool isBusy;

  const SaveExpenseButton({
    super.key,
    required this.onPressed,
    this.label,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBottomActionBar(
      primaryLabel: label ?? 'expense.save'.tr(),
      primaryIcon: LucideIcons.check,
      isLoading: isBusy,
      onPrimary: onPressed,
    );
  }
}
