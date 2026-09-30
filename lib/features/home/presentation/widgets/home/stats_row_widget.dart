import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/home/business_logic/home_stats_cubit.dart';
import 'package:resi_africa/features/home/business_logic/home_stats_state.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

/// Chiffres du mois sur l'accueil, en tuiles comme le tableau de bord du
/// backoffice.
///
/// Le `HomeStatsCubit` est fourni par l'écran et non créé ici : l'accueil
/// reste monté dans l'`IndexedStack`, et un cubit local ne serait jamais
/// rechargé après l'ajout d'un bien ou d'une dépense.
class StatsRowWidget extends StatelessWidget {
  const StatsRowWidget({super.key});

  /// Valeur affichée tant qu'un relevé n'est pas arrivé, ou qu'il a échoué.
  ///
  /// Un tiret plutôt qu'un zéro : « 0 bien » est une information, l'absence de
  /// donnée n'en est pas une.
  static const _placeholder = '—';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeStatsCubit, HomeStatsState>(
      builder: (context, state) {
        // Le gérant a sa propre rangée : mêmes tuiles, mêmes couleurs, mais
        // alimentées par son seul relevé et sans aucun bénéfice net.
        if (state is HomeStatsManagerLoaded) return _managerTiles(state);

        final stats = state is HomeStatsLoaded ? state : null;
        final netIncome = stats?.netIncome;
        // Un mois de travaux sans réservation est une perte : la montrer en
        // rouge vaut mieux que la masquer.
        final isLoss = netIncome != null && netIncome < 0;

        return _TileLayout(
          lead: StatTile(
            label: 'Bénéfice ce mois',
            value: netIncome == null
                ? _placeholder
                : CurrencyFormatter.short(netIncome),
            icon: LucideIcons.banknote,
            accent: isLoss ? AppAccent.red : AppAccent.green,
            note: isLoss ? 'Mois en perte' : 'Recettes moins dépenses',
            noteTone: isLoss ? StatNoteTone.down : null,
          ),
          pair: [
            StatTile(
              label: 'Mes biens',
              value: stats?.propertiesCount?.toString() ?? _placeholder,
              icon: AppSectionIcons.properties,
              accent: AppAccent.blue,
            ),
            StatTile(
              label: 'Réservations ce mois',
              value: stats?.activeBookings?.toString() ?? _placeholder,
              icon: AppSectionIcons.bookings,
              accent: AppAccent.violet,
            ),
          ],
        );
      },
    );
  }

  /// Tuiles du gérant : réservations, encaissements, occupation du mois.
  ///
  /// Même disposition que celle du propriétaire, alimentées par son seul
  /// périmètre. La tuile du bénéfice net devient le taux d'occupation : sur
  /// un périmètre partiel, un net déduirait des charges qui ne relèvent pas du
  /// gérant — abonnement du propriétaire, charges communes, dépenses d'autres
  /// logements —, ce qui n'est pas une marge partielle mais un chiffre faux.
  /// Rien ici ne le reconstitue par soustraction.
  Widget _managerTiles(HomeStatsManagerLoaded stats) {
    final grossRevenue = stats.grossRevenue;
    final occupancyRate = stats.occupancyRate;

    return _TileLayout(
      lead: StatTile(
        label: 'Encaissé ce mois',
        value: grossRevenue == null
            ? _placeholder
            : CurrencyFormatter.short(grossRevenue),
        icon: LucideIcons.banknote,
        accent: AppAccent.green,
      ),
      pair: [
        StatTile(
          label: 'Réservations ce mois',
          value: stats.bookingsCount?.toString() ?? _placeholder,
          icon: AppSectionIcons.bookings,
          accent: AppAccent.violet,
        ),
        StatTile(
          label: 'Occupation',
          // Le serveur rend une part de 0 à 1 : affichée en pourcentage
          // entier, dans la forme déjà retenue par l'onglet Statistiques.
          value: occupancyRate == null
              ? _placeholder
              : '${(occupancyRate * 100).toStringAsFixed(0)} %',
          icon: LucideIcons.chartPie,
          accent: AppAccent.amber,
        ),
      ],
    );
  }
}

/// Chiffre principal en pleine largeur, puis deux tuiles côte à côte : le
/// montant du mois se lit d'abord.
class _TileLayout extends StatelessWidget {
  const _TileLayout({required this.lead, required this.pair});

  final Widget lead;
  final List<Widget> pair;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        lead,
        const SizedBox(height: 12),
        StatGrid(children: pair),
      ],
    );
  }
}
