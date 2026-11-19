import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/frosted_surface.dart';

/// Bouton de génération, dans une barre de verre flottante comme la barre
/// « Réserver » des maquettes.
class GenerateButton extends StatelessWidget {
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const GenerateButton({
    super.key,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Hauteur de son contenu : un `bottomNavigationBar` reçoit toute la
    // hauteur disponible.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: FrostedSurface(
              borderRadius: FrostedSurface.pill,
              padding: const EdgeInsets.all(8),
              child: AppButton(
                label: 'report.generate'.tr(),
                icon: LucideIcons.fileText,
                expand: true,
                isLoading: isLoading,
                onPressed: enabled ? onTap : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
