import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';

class ExportButton extends StatelessWidget {
  final VoidCallback? onTap;

  const ExportButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'expense.export_full'.tr(),
      icon: LucideIcons.download,
      variant: AppButtonVariant.secondary,
      expand: true,
      onPressed: onTap,
    );
  }
}
