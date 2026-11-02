import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';

/// Barre d'enregistrement d'une fiche client.
class SubmitClientButton extends StatelessWidget {
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  /// Le défaut porte l'enregistrement d'un nouveau client ; l'édition d'une
  /// fiche existante le remplace.
  final String? label;

  const SubmitClientButton({
    super.key,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AppBottomActionBar(
      primaryLabel: label ?? 'clients.save_client'.tr(),
      primaryIcon: LucideIcons.check,
      isLoading: isLoading,
      onPrimary: enabled ? onTap : null,
    );
  }
}
