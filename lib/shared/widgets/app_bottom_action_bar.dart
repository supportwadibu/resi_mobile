import 'package:flutter/material.dart';

import '../../core/theme/resi_tokens.dart';
import 'app_button.dart';

class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.primaryIcon,
    this.secondaryIcon,
    this.primaryVariant = AppButtonVariant.primary,
    this.isLoading = false,
    this.footer,
  }) : assert(
         secondaryLabel == null || onSecondary != null,
         'secondaryLabel nécessite onSecondary',
       );

  final String primaryLabel;

  final VoidCallback? onPrimary;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  final IconData? primaryIcon;
  final IconData? secondaryIcon;

  final AppButtonVariant primaryVariant;

  final bool isLoading;

  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (secondaryLabel != null) ...[
                    Expanded(
                      child: AppButton(
                        label: secondaryLabel!,
                        onPressed: isLoading ? null : onSecondary,
                        variant: AppButtonVariant.secondary,
                        icon: secondaryIcon,
                        expand: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: primaryLabel,
                      onPressed: onPrimary,
                      isLoading: isLoading,
                      variant: primaryVariant,
                      trailingIcon: primaryIcon,
                      expand: true,
                    ),
                  ),
                ],
              ),
              if (footer != null) ...[const SizedBox(height: 8), footer!],
            ],
          ),
        ),
      ),
    );
  }
}
