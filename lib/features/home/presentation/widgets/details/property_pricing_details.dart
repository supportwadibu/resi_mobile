import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/app_badge.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import '../../../../property/data/models/property_model.dart';

/// Grille tarifaire d'un bien : le prix par jour, puis les remises de durée.
///
/// Chaque palier est présenté par son prix au jour remisé plutôt que par le
/// seul pourcentage : c'est le montant que le locataire compare.
class PropertyPricingDetails extends StatelessWidget {
  const PropertyPricingDetails({
    super.key,
    required this.pricePerDay,
    this.priceTiers = const [],
  });

  final double pricePerDay;
  final List<PriceTier> priceTiers;

  @override
  Widget build(BuildContext context) {
    return Section(
      title: 'Tarifs',
      icon: LucideIcons.banknote,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _PriceRow(label: 'Par jour', price: pricePerDay),
          for (final tier in priceTiers) ...[
            const Divider(height: 1),
            _PriceRow(
              label: 'Dès ${tier.minDays} jours',
              price: pricePerDay * (1 - tier.discountPercent / 100),
              // Une remise est un avantage acquis : vert, comme un statut
              // « en règle ».
              badge: AppBadge(
                label: '-${tier.discountPercent} %',
                tone: AppAccent.green,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.price, this.badge});

  final String label;
  final double price;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(label, style: context.mutedText),
          if (badge != null) ...[const SizedBox(width: 8), badge!],
          const Spacer(),
          Text(CurrencyFormatter.short(price), style: context.text.amount),
        ],
      ),
    );
  }
}
