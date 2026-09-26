import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/resi_tokens.dart';

/// Barre des onglets racines : pleine largeur, fond de surface, filet haut,
/// indicateur carré. Les icônes sont celles des sections (`AppSectionIcons`),
/// reprises sur les tuiles et les en-têtes.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.tokens.border)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(AppSectionIcons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(AppSectionIcons.bookings),
            label: 'Réservations',
          ),
          NavigationDestination(
            icon: Icon(AppSectionIcons.properties),
            label: 'Biens',
          ),
          NavigationDestination(
            icon: Icon(AppSectionIcons.stats),
            label: 'Stats',
          ),
        ],
      ),
    );
  }
}
