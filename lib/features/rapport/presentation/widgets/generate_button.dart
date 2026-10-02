import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';

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
    return AppBottomActionBar(
      primaryLabel: 'report.generate'.tr(),
      primaryIcon: LucideIcons.fileText,
      isLoading: isLoading,
      onPrimary: enabled ? onTap : null,
    );
  }
}
