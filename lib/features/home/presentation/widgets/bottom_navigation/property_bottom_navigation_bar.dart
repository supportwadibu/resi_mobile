import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';
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
    // if (canChangeVisibility) : PropertyVisibilitySwitch(
    //   isPublished: isPublished,
    //   isBusy: isTogglingVisibility,
    //   onChanged: onVisibilityChanged,
    // ), posée au-dessus du bouton.
    return AppBottomActionBar(
      primaryLabel: 'Modifier ce bien',
      primaryIcon: LucideIcons.pencil,
      onPrimary: onEditPressed,
    );
  }
}
