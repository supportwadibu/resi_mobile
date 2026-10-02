import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

/// Titre de l'aperçu des biens, avec l'accès à la liste complète.
class HeaderPropertyWidget extends StatelessWidget {
  const HeaderPropertyWidget({super.key, this.onSeeAll});

  /// Ouvre la liste complète. `null` masque l'action.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return SectionHeading(
      title: 'home.my_properties'.tr(),
      icon: AppSectionIcons.properties,
      actionLabel: 'common.see_all'.tr(),
      onAction: onSeeAll,
    );
  }
}
