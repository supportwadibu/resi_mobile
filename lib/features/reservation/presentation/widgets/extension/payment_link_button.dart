import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';

/// Barre de validation de la prolongation.
class PaymentLinkButton extends StatelessWidget {
  /// `null` désactive le bouton — pendant l'envoi, notamment.
  final VoidCallback? onPressed;

  /// Remplace le libellé par un indicateur de progression.
  ///
  /// Sans lui, rien ne distinguerait un envoi en cours d'un appui sans effet,
  /// et le propriétaire réappuierait en croyant que rien ne s'est passé.
  final bool isLoading;

  const PaymentLinkButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBottomActionBar(
      primaryLabel: 'stay_extension.title'.tr(),
      primaryIcon: LucideIcons.calendarPlus,
      isLoading: isLoading,
      onPrimary: onPressed,
    );
  }
}
