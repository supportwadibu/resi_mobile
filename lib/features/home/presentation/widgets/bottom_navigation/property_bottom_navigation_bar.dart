import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'property_edit_button.dart';
// import 'property_visibility_switch.dart';

class PropertyBottomNavigationBar extends StatelessWidget {
  const PropertyBottomNavigationBar({
    super.key,
    required this.onEditPressed,
    required this.isPublished,
    required this.onVisibilityChanged,
    this.isTogglingVisibility = false,
    this.canChangeVisibility = true,
  });

  final VoidCallback onEditPressed;

  final bool isPublished;

  final ValueChanged<bool> onVisibilityChanged;

  final bool isTogglingVisibility;

  /// Faux quand le rôle ne met pas d'annonce en ligne : la bascule n'est alors
  /// pas construite. `publish` et `unpublish` n'ont pas d'équivalent gérant —
  /// le repository vise `/proprio/...` en dur et le serveur répond 403.
  final bool canChangeVisibility;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey500.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // if (canChangeVisibility) ...[
              //   PropertyVisibilitySwitch(
              //     isPublished: isPublished,
              //     isBusy: isTogglingVisibility,
              //     onChanged: onVisibilityChanged,
              //   ),
              //   const SizedBox(height: 12),
              // ],
              Row(
                children: [
                  Expanded(child: PropertyEditButton(onPressed: onEditPressed)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
