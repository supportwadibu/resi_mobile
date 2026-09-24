import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/features/reservation/data/models/booking_stats_model.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';

import 'revenue_stat.dart';

class RevenueCard extends StatelessWidget {
  const RevenueCard({super.key, this.revenue});

  /// `null` tant que les chiffres ne sont pas arrivés : la carte garde sa
  /// hauteur et affiche des tirets plutôt que de se déplier d'un coup.
  final BookingRevenueStats? revenue;

  /// Croissance signée, ou un tiret quand le mois précédent est à zéro : une
  /// progression depuis rien n'a pas de valeur à afficher.
  String get _growthLabel {
    final growth = revenue?.growthPercent;
    if (growth == null) return '—';

    final rounded = growth.round();
    return '${rounded >= 0 ? '+' : ''}$rounded%';
  }

  @override
  Widget build(BuildContext context) {
    final revenue = this.revenue;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revenus ce mois',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  revenue == null
                      ? '—'
                      : CurrencyFormatter.short(revenue.currentMonth),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    RevenueStat(
                      label: 'Mois dernier',
                      value: revenue == null
                          ? '—'
                          : CurrencyFormatter.short(revenue.previousMonth),
                    ),
                    const SizedBox(width: 24),
                    RevenueStat(label: 'Croissance', value: _growthLabel),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 18,
                  top: -18,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 22,
                  top: 16,
                  child: FaIcon(
                    FontAwesomeIcons.sackDollar,
                    size: 72,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
