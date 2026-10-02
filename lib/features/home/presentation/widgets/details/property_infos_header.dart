import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';

/// En-tête d'une fiche de bien : nom, ville, tarif journalier.
class PropertyInfosHeader extends StatelessWidget {
  const PropertyInfosHeader({
    super.key,
    required this.name,
    required this.location,
    required this.pricePerDay,
    this.status,
  });

  final String name;
  final String location;
  final double pricePerDay;

  /// Badge de statut posé sous le nom (en ligne, brouillon…).
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: context.text.headlineSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.mapPin, size: 14, color: t.muted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      location,
                      overflow: TextOverflow.ellipsis,
                      style: context.mutedText,
                    ),
                  ),
                ],
              ),
              if (status != null) ...[const SizedBox(height: 8), status!],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.short(pricePerDay),
              style: context.text.figure.copyWith(fontSize: 20),
            ),
            Text('property_detail.per_day'.tr(), style: context.text.bodySmall),
          ],
        ),
      ],
    );
  }
}
