import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/status_badge.dart';

import '../../../property/data/models/property_model.dart';

/// Un logement de la résidence, dans la liste de sa fiche.
class ResidenceUnitTile extends StatelessWidget {
  const ResidenceUnitTile({super.key, required this.unit, this.onTap});

  final PropertyModel unit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const IconChip(icon: LucideIcons.doorOpen, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // Le nom d'unité prime : dans une résidence, « Studio 1 »
                    // situe mieux qu'un titre d'annonce rédigé pour la
                    // vitrine publique.
                    unit.unitLabel?.trim().isNotEmpty == true
                        ? unit.unitLabel!
                        : unit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'residence.price_per_day'.tr(
                      args: [CurrencyFormatter.short(unit.pricing.dailyPrice)],
                    ),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(
              label: unit.status.label,
              tone: StatusTones.property(unit.status.code),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: context.tokens.muted,
            ),
          ],
        ),
      ),
    );
  }
}
