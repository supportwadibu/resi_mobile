import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/home/business_logic/home_stats_cubit.dart';
import 'package:resi_africa/features/home/business_logic/home_stats_state.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/motion/motion.dart';
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

        // Sans bénéfice — RESI Basic ne suit pas les charges —, la rangée
        // montre ce que ce palier promet : revenus et occupation du mois.
        if (stats != null &&
            stats.netIncome == null &&
            stats.monthRevenue != null) {
          return _revenueTiles(stats);
        }

        final netIncome = stats?.netIncome;
        // Un mois de travaux sans réservation est une perte : la montrer en
        // rouge vaut mieux que la masquer.
        final isLoss = netIncome != null && netIncome < 0;

        return _TileLayout(
          lead: StatTile(
            label: 'home.net_income'.tr(),
            value: netIncome == null
                ? _placeholder
                : CurrencyFormatter.short(netIncome),
            icon: LucideIcons.banknote,
            accent: isLoss ? AppAccent.red : AppAccent.violet,
            // Une perte reste sur fond neutre : le rouge de la note s'y lit mieux.
            surface: isLoss ? StatSurface.neutral : StatSurface.lavender,
            note: isLoss
                ? 'home.month_loss'.tr()
                : 'home.income_minus_expenses'.tr(),
            noteTone: isLoss ? StatNoteTone.down : null,
          ),
          pair: [
            StatTile(
              label: 'home.my_properties'.tr(),
              value: stats?.propertiesCount?.toString() ?? _placeholder,
              icon: AppSectionIcons.properties,
              surface: StatSurface.lavender,
            ),
            if (stats?.occupancyRate case final rate?)
              StatTile(
                label: 'common.occupancy'.tr(),
                value: '${(rate * 100).toStringAsFixed(0)} %',
                icon: LucideIcons.chartPie,
              ),
            if (stats?.monthRevenue case final revenue?)
              StatTile(
                label: 'home.revenue_month'.tr(),
                value: CurrencyFormatter.short(revenue),
                icon: LucideIcons.banknote,
              ),
            StatTile(
              label: 'home.bookings_month'.tr(),
              value: stats?.activeBookings?.toString() ?? _placeholder,
              icon: AppSectionIcons.bookings,
              accent: AppAccent.amber,
              surface: StatSurface.sand,
            ),
          ],
        );
      },
    );
  }

  /// Tuiles du propriétaire sous RESI Basic : revenus, séjours et occupation
  /// du mois — même disposition que celles du gérant.
  Widget _revenueTiles(HomeStatsLoaded stats) {
    final occupancyRate = stats.occupancyRate;

    return _TileLayout(
      lead: StatTile(
        label: 'home.revenue_month'.tr(),
        value: CurrencyFormatter.short(stats.monthRevenue!),
        icon: LucideIcons.banknote,
        accent: AppAccent.violet,
        surface: StatSurface.lavender,
      ),
      pair: [
        StatTile(
          label: 'home.bookings_month'.tr(),
          value: stats.activeBookings?.toString() ?? _placeholder,
          icon: AppSectionIcons.bookings,
          accent: AppAccent.amber,
          surface: StatSurface.sand,
        ),
        StatTile(
          label: 'common.occupancy'.tr(),
          value: occupancyRate == null
              ? _placeholder
              : '${(occupancyRate * 100).toStringAsFixed(0)} %',
          icon: LucideIcons.chartPie,
        ),
      ],
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
        label: 'home.collected_month'.tr(),
        value: grossRevenue == null
            ? _placeholder
            : CurrencyFormatter.short(grossRevenue),
        icon: LucideIcons.banknote,
        accent: AppAccent.violet,
        surface: StatSurface.lavender,
      ),
      pair: [
        StatTile(
          label: 'home.bookings_month'.tr(),
          value: stats.bookingsCount?.toString() ?? _placeholder,
          icon: AppSectionIcons.bookings,
          accent: AppAccent.amber,
          surface: StatSurface.sand,
        ),
        StatTile(
          label: 'common.occupancy'.tr(),
          // Le serveur rend une part de 0 à 1 : affichée en pourcentage
          // entier, dans la forme déjà retenue par l'onglet Statistiques.
          value: occupancyRate == null
              ? _placeholder
              : '${(occupancyRate * 100).toStringAsFixed(0)} %',
          icon: LucideIcons.chartPie,
        ),
      ],
    );
  }
}

/// Chiffre principal en pleine largeur, puis deux tuiles côte à côte : le
/// montant du mois se lit d'abord.
/// Disposition des maquettes : le chiffre de tête en grande carte lavande,
/// les autres en grille de deux colonnes. Les tuiles portent leurs données
/// (`StatTile`) ; la disposition seule décide de leur dessin.
class _TileLayout extends StatelessWidget {
  const _TileLayout({required this.lead, required this.pair});

  final StatTile lead;
  final List<StatTile> pair;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < pair.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _GridTile(tile: pair[i])),
            const SizedBox(width: 10),
            Expanded(
              child: i + 1 < pair.length
                  ? _GridTile(tile: pair[i + 1])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroTile(tile: lead),
        for (final row in rows) ...[const SizedBox(height: 10), row],
      ],
    );
  }
}

/// Carte de tête : mois en pastille, libellé, montant en grand. Lavande, ou
/// neutre pour une perte — le rouge de la note s'y lit mieux.
class _HeroTile extends StatelessWidget {
  const _HeroTile({required this.tile});

  final StatTile tile;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final tinted = tile.surface != StatSurface.neutral;
    final fg = tinted ? t.onLavender : t.foreground;
    final month = DateFormat.MMMM(
      Localizations.localeOf(context).toString(),
    ).format(DateTime.now());
    final body = Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TagPill(
            label: toBeginningOfSentenceCase(month),
            color: fg.withValues(alpha: 0.1),
            foreground: fg,
          ),
          const SizedBox(height: 6),
          Text(tile.label, style: context.text.titleSmall!.copyWith(color: fg)),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: CountUpText(
                    tile.value,
                    style: context.text.figure.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
              ),
              if (tile.note != null) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    tile.note!,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    style: context.text.bodySmall!.copyWith(
                      color: tile.noteTone == StatNoteTone.down
                          ? t.accentRed
                          : fg.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
    return Material(
      color: tinted ? t.lavender : t.surface,
      shape: AppRadius.outlined(AppRadius.lg, tinted ? t.lavender : t.border),
      clipBehavior: Clip.antiAlias,
      child: tinted ? HaloSurface(radius: AppRadius.lg, child: body) : body,
    );
  }
}

/// Tuile de la grille : disque d'icône et flèche en haut, chiffre en grand
/// puis libellé en entier dessous. Le libellé a toute la largeur de la tuile
/// — posé en pastille à côté de l'icône, il se coupait (« Occu… »).
/// Sable, lavande douce ou neutre.
class _GridTile extends StatelessWidget {
  const _GridTile({required this.tile});

  final StatTile tile;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (bg, fg) = switch (tile.surface) {
      StatSurface.sand => (t.sand, t.onSand),
      StatSurface.lavender => (t.accentVioletSoft, t.foreground),
      StatSurface.neutral => (t.surface, t.foreground),
    };
    final neutral = tile.surface == StatSurface.neutral;
    final sand = tile.surface == StatSurface.sand;
    // Disque blanc sur le sable, dans les deux modes : un disque de surface
    // y devenait sombre en mode sombre, et l'icône sombre disparaissait.
    final disc = sand
        ? t.onOverlay
        : neutral
        ? t.background
        : t.surface;
    final body = SizedBox(
      height: 132,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: disc,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 36,
                    child: Icon(
                      tile.icon,
                      size: 16,
                      color: sand ? t.onSand : t.foreground,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  LucideIcons.arrowUpRight,
                  size: 16,
                  color: fg.withValues(alpha: 0.6),
                ),
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: CountUpText(
                tile.value,
                style: context.text.figure.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tile.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium!.copyWith(
                color: fg.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
    return Material(
      color: bg,
      shape: AppRadius.outlined(AppRadius.lg, neutral ? t.border : bg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tile.onTap,
        child: HaloSurface(radius: AppRadius.lg, child: body),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.color,
    required this.foreground,
  });

  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall!.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
