import 'package:flutter/material.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détails des prix',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E2A5A),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _PriceRow(
                icon: Icons.wb_sunny_rounded,
                iconBg: const Color(0xFFE6F1FB),
                iconColor: const Color(0xFF185FA5),
                label: 'Par jour',
                price: pricePerDay,
                showDivider: priceTiers.isNotEmpty,
              ),
              for (final (index, tier) in priceTiers.indexed)
                _PriceRow(
                  icon: Icons.calendar_month_rounded,
                  iconBg: const Color(0xFFEAF3DE),
                  iconColor: const Color(0xFF3B6D11),
                  label: 'Dès ${tier.minDays} jours',
                  price: pricePerDay * (1 - tier.discountPercent / 100),
                  showDivider: index < priceTiers.length - 1,
                  badge: '-${tier.discountPercent}%',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.price,
    required this.showDivider,
    this.badge,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final double price;
  final bool showDivider;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3DE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF3B6D11),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${_formatPrice(price)} F',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2A5A),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ');
  }
}
