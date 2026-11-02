import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';

import '../../../property/data/models/property_model.dart';

/// Choix d'un logement à rattacher à la résidence.
///
/// Inverse d'`AttachResidenceSheet`, qui part d'un bien pour lui choisir une
/// résidence : ici le lieu est connu, et c'est l'unité qu'on désigne.
class AttachUnitSheet extends StatelessWidget {
  const AttachUnitSheet({
    super.key,
    required this.residenceName,
    required this.candidates,
  });

  final String residenceName;

  /// Biens rattachables — ceux qui n'appartiennent à aucune résidence.
  final List<PropertyModel> candidates;

  static Future<PropertyModel?> show(
    BuildContext context, {
    required String residenceName,
    required List<PropertyModel> candidates,
  }) {
    return showAppSheet<PropertyModel>(
      context: context,
      builder: (_) =>
          AttachUnitSheet(residenceName: residenceName, candidates: candidates),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'residence.attach_unit'.tr(),
      description: 'residence.attach_unit_body'.tr(args: [residenceName]),
      padding: const EdgeInsets.only(bottom: 8),
      child: candidates.isEmpty
          // Tous les biens sont déjà rattachés, ou le parc est vide.
          ? EmptyState(
              icon: AppSectionIcons.properties,
              message: 'residence.no_unit_available'.tr(),
            )
          : Column(
              children: [
                for (final property in candidates)
                  AppSheetAction(
                    icon: LucideIcons.doorOpen,
                    label: property.title,
                    description: property.address.city,
                    trailing: const Icon(LucideIcons.plus, size: 16),
                    onTap: () => Navigator.of(context).pop(property),
                  ),
              ],
            ),
    );
  }
}
