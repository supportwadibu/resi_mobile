import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/reservation/data/models/booking_stats_model.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

/// Revenus du mois, comparés au mois précédent.
class RevenueCard extends StatelessWidget {
  const RevenueCard({super.key, this.revenue});

  /// `null` tant que les chiffres ne sont pas arrivés : la tuile garde sa
  /// hauteur et affiche des tirets plutôt que de se déplier d'un coup.
  final BookingRevenueStats? revenue;

  @override
  Widget build(BuildContext context) {
    final revenue = this.revenue;
    final growth = revenue?.growthPercent;

    final previous = revenue == null
        ? null
        : CurrencyFormatter.short(revenue.previousMonth);
    // Croissance signée, absente quand le mois précédent est à zéro : une
    // progression depuis rien n'a pas de valeur à afficher.
    final note = previous == null
        ? null
        : growth == null
        ? 'Mois dernier : $previous'
        : '${growth.round() >= 0 ? '+' : ''}${growth.round()} % '
              'par rapport au mois dernier ($previous)';

    return StatTile(
      label: 'Revenus ce mois',
      value: revenue == null
          ? '—'
          : CurrencyFormatter.short(revenue.currentMonth),
      icon: LucideIcons.wallet,
      accent: AppAccent.green,
      note: note,
      noteTone: growth == null
          ? null
          : growth >= 0
          ? StatNoteTone.up
          : StatNoteTone.down,
    );
  }
}
