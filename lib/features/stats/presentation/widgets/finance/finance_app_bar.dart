import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';

/// Barre de l'écran financier. Les filtres (périmètre, période) vivent sous
/// le titre, dans l'écran : la barre des maquettes ne porte que le retour.
class FinanceAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FinanceAppBar({super.key});

  static final _bar = AppTopBar(title: '');

  /// La hauteur d'`AppTopBar` elle-même : une valeur écrite ici à la main
  /// (56) écrasait le grand titre sous la barre.
  @override
  Size get preferredSize => _bar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return AppTopBar(title: 'finance_page.title'.tr());
  }
}
