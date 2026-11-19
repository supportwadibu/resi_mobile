import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Barres système transparentes, icônes à la couleur du mode affiché.
///
/// Posé à la racine : sans lui, un écran sans `AppBar` garde le style de la
/// dernière barre vue, et l'encoche reste noire sur un fond crème — ou des
/// icônes sombres sur le fond prune du mode sombre.
class SystemBars extends StatelessWidget {
  const SystemBars({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final icons = dark ? Brightness.light : Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: icons,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: icons,
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}
