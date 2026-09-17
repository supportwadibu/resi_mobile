import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/features/feedback/presentation/widgets/feedback_sheet.dart';
import 'package:resi_africa/features/home/business_logic/home_stats_cubit.dart';
import 'package:resi_africa/features/home/business_logic/home_stats_state.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';

/// Rangée de chiffres de l'accueil.
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
        if (state is HomeStatsManagerLoaded) {
          return _managerRows(context, state);
        }

        final stats = state is HomeStatsLoaded ? state : null;
        final netIncome = stats?.netIncome;

        return Column(
          children: [
            Row(
              children: [
                StatBoxWidget(
                  value: stats?.propertiesCount?.toString() ?? _placeholder,
                  label: 'Mes biens',
                  icon: FontAwesomeIcons.building,
                ),
                const SizedBox(width: 10),
                StatBoxWidget(
                  value: stats?.activeBookings?.toString() ?? _placeholder,
                  label: 'Réservations ce mois',
                  icon: FontAwesomeIcons.calendarCheck,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                StatBoxWidget(
                  value: netIncome == null
                      ? _placeholder
                      : CurrencyFormatter.short(netIncome),
                  label: 'Bénéfice ce mois',
                  icon: FontAwesomeIcons.moneyBillWave,
                  // Un mois de travaux sans réservation est une perte : la
                  // montrer en rouge vaut mieux que la masquer.
                  isNegative: netIncome != null && netIncome < 0,
                ),
                const SizedBox(width: 10),
                StatBoxWidget(
                  value: 'Avis',
                  label: 'Laisser un commentaire',
                  icon: FontAwesomeIcons.message,
                  isAction: true,
                  onTap: () => showFeedbackSheet(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Rangée du gérant : réservations, encaissements, occupation du mois.
  ///
  /// Même disposition et mêmes tuiles que celle du propriétaire, alimentées par
  /// son seul périmètre. La tuile du bénéfice net devient le taux d'occupation :
  /// sur un périmètre partiel, un net déduirait des charges qui ne relèvent pas
  /// du gérant — abonnement du propriétaire, charges communes, dépenses
  /// d'autres logements —, ce qui n'est pas une marge partielle mais un chiffre
  /// faux. Rien ici ne le reconstitue par soustraction.
  Widget _managerRows(BuildContext context, HomeStatsManagerLoaded stats) {
    final grossRevenue = stats.grossRevenue;
    final occupancyRate = stats.occupancyRate;

    return Column(
      children: [
        Row(
          children: [
            StatBoxWidget(
              value: stats.bookingsCount?.toString() ?? _placeholder,
              label: 'Réservations ce mois',
              icon: FontAwesomeIcons.calendarCheck,
            ),
            const SizedBox(width: 10),
            StatBoxWidget(
              value: grossRevenue == null
                  ? _placeholder
                  : CurrencyFormatter.short(grossRevenue),
              label: 'Encaissé ce mois',
              icon: FontAwesomeIcons.moneyBillWave,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            StatBoxWidget(
              // Le serveur rend une part de 0 à 1 : affichée en pourcentage
              // entier, dans la forme déjà retenue par l'onglet Statistiques.
              value: occupancyRate == null
                  ? _placeholder
                  : '${(occupancyRate * 100).toStringAsFixed(0)}%',
              label: 'Occupation',
              icon: FontAwesomeIcons.chartPie,
            ),
            const SizedBox(width: 10),
            StatBoxWidget(
              value: 'Avis',
              label: 'Laisser un commentaire',
              icon: FontAwesomeIcons.message,
              isAction: true,
              onTap: () => showFeedbackSheet(context),
            ),
          ],
        ),
      ],
    );
  }
}

class StatBoxWidget extends StatelessWidget {
  const StatBoxWidget({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.isAction = false,
    this.isNegative = false,
    this.onTap,
  });

  final String value;
  final String label;
  final FaIconData? icon;
  final bool isAction;

  /// Montant en perte, signalé par la couleur d'erreur du thème.
  final bool isNegative;

  final VoidCallback? onTap;

  Color get _color => switch ((isAction, isNegative)) {
    (true, _) => AppColors.primary,
    (false, true) => AppColors.error,
    (false, false) => AppColors.black,
  };

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.grey200.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              // Icône
              if (icon != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: switch ((isAction, isNegative)) {
                      (true, _) => AppColors.primary.withValues(alpha: 0.1),
                      (false, true) => AppColors.errorBg,
                      (false, false) => AppColors.surface,
                    },
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: FaIcon(icon, size: 18, color: _color)),
                ),

              if (icon != null) const SizedBox(width: 12),

              // Textes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
