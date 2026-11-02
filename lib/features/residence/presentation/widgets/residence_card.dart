import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/app_badge.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

import '../../data/models/residence_model.dart';

/// Une résidence dans la liste, avec son nombre de logements.
class ResidenceCard extends StatelessWidget {
  const ResidenceCard({
    super.key,
    required this.residence,
    this.onTap,
    this.onDelete,
  });

  final ResidenceModel residence;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final count = residence.unitsCount;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const IconChip(icon: AppSectionIcons.residences, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  residence.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 12,
                      color: context.tokens.muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        residence.address.city,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Une résidence vide est signalée en clair, en ambre : elle
                // n'est pas encore louable, et c'est la seule chose à faire
                // ensuite.
                AppBadge(
                  label: switch (count) {
                    0 => 'residence.no_unit'.tr(),
                    _ => 'residence.unit_count'.plural(count),
                  },
                  icon: count == 0 ? LucideIcons.info : LucideIcons.doorOpen,
                  tone: count == 0 ? AppAccent.amber : AppAccent.neutral,
                ),
              ],
            ),
          ),
          if (onDelete != null)
            AppIconButton(
              icon: LucideIcons.trash2,
              label: 'common.delete'.tr(),
              danger: true,
              onPressed: onDelete,
            )
          else
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: context.tokens.muted,
            ),
        ],
      ),
    );
  }
}
