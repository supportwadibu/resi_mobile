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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != null) ...[status!, const SizedBox(height: 10)],
          Text(name, style: context.text.displaySmall!.copyWith(fontSize: 30)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(LucideIcons.mapPin, size: 15, color: t.muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  location,
                  overflow: TextOverflow.ellipsis,
                  style: context.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: CurrencyFormatter.short(pricePerDay),
                  style: context.text.figure.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' ${'property_detail.per_day'.tr()}',
                  style: context.mutedText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
