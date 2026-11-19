import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/failures.dart';
import '../../../expense/business_logic/expense_cubit.dart';
import '../../../expense/business_logic/expense_state.dart';
import '../../../expense/data/models/expense_category_model.dart';
import '../../../expense/presentation/widgets/stats/expense_breakdown_card.dart';
import '../../business_logic/finance_cubit.dart';
import '../../business_logic/finance_state.dart';
import '../../data/models/finance/finance_overview_model.dart';
import '../../data/models/finance/finance_period.dart';
import '../../../property/data/models/property_model.dart';
import '../../../property/data/repositories/property_repository.dart';
import '../../../residence/data/models/residence_model.dart';
import '../../../residence/data/repositories/residence_repository.dart';
import '../widgets/finance/finance_app_bar.dart';
import '../widgets/finance/finance_period_sheet.dart';
import '../widgets/finance/finance_scope_sheet.dart';
import '../widgets/finance/revenue_chart.dart';
import '../widgets/finance/stats_row.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/shared/widgets/loading_shimmer.dart';

@RoutePage()
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<FinanceCubit>()..load()),
        BlocProvider(
          create: (_) {
            // La ventilation porte sur la fenêtre du relevé. Sans bornes, elle
            // couvrait tout l'historique sous un relevé de douze mois, et ses
            // catégories ne sommaient pas au total « Dépenses » affiché
            // au-dessus.
            final bounds = const FinancePeriod.rolling().bounds(DateTime.now());
            return sl<ExpenseCubit>()..load(
              filters: ExpenseFilters(
                periodKind: ExpensePeriodKind.range,
                from: bounds.from,
                to: bounds.to,
              ),
            );
          },
        ),
      ],
      child: const _FinanceView(),
    );
  }
}

class _FinanceView extends StatefulWidget {
  const _FinanceView();

  @override
  State<_FinanceView> createState() => _FinanceViewState();
}

class _FinanceViewState extends State<_FinanceView>
    with AutoRouteAwareStateMixin<_FinanceView> {
  @override
  void didPopNext() {
    context.read<FinanceCubit>().load();
    context.read<ExpenseCubit>().refresh();
  }

  Future<void> _pickScope() async {
    final cubit = context.read<FinanceCubit>();

    final List<ResidenceModel> residences;
    final List<PropertyModel> properties;
    try {
      // `Future.wait` relève la première erreur telle quelle : l'`AppFailure`
      // d'un des deux appels arrive ici sans enveloppe.
      final [
        residenceList as List<ResidenceModel>,
        propertyList as List<PropertyModel>,
      ] = await Future.wait<Object>([
        sl<ResidenceRepository>().getAllResidences(),
        sl<PropertyRepository>().getAllProperties(),
      ]);
      residences = residenceList;
      properties = propertyList;
    } on AppFailure catch (f) {
      AppToast.error(f.userMessage);
      return;
    }

    if (!mounted) return;

    final scope = await FinanceScopeSheet.show(
      context,
      residences: residences,
      properties: properties,
      selected: cubit.scope,
    );

    if (scope == null || !mounted) return;

    await cubit.filterByScope(scope);

    if (!mounted) return;

    // La ventilation suit le même périmètre que le relevé, faute de quoi ses
    // catégories ne sommeraient pas au total « Dépenses » affiché au-dessus.
    // Les deux rattachements sont exclusifs côté dépenses aussi : poser l'un
    // lève l'autre.
    final expenses = context.read<ExpenseCubit>();
    await expenses.applyFilters(
      expenses.filters.copyWith(
        residenceId: scope.residenceId,
        propertyId: scope.propertyId,
        clearResidence: scope.residenceId == null,
        clearProperty: scope.propertyId == null,
      ),
    );
  }

  Future<void> _pickPeriod() async {
    final cubit = context.read<FinanceCubit>();

    final period = await FinancePeriodSheet.show(
      context,
      selected: cubit.period,
    );

    if (period == null || !mounted) return;

    await cubit.filterByPeriod(period);

    if (!mounted) return;

    // Bornes lues sur le cubit, celles-là mêmes qui ont servi au relevé : la
    // ventilation des dépenses doit sommer au total « Dépenses » affiché.
    final expenses = context.read<ExpenseCubit>();
    await expenses.applyFilters(
      expenses.filters.copyWith(from: cubit.from, to: cubit.to),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FinanceAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hors de la liste : périmètre et période restent lisibles, et
          // modifiables, pendant le chargement comme après une erreur.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: _Filters(onScope: _pickScope, onPeriod: _pickPeriod),
          ),
          Expanded(
            child: BlocBuilder<FinanceCubit, FinanceState>(
              builder: (context, state) => switch (state) {
                FinanceInitial() || FinanceLoading() => const _Skeleton(),
                FinanceError(:final message) => ErrorState(
                  message: message,
                  onRetry: () => context.read<FinanceCubit>().load(),
                ),
                FinanceLoaded(:final overview) => _Content(overview: overview),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Périmètre et période en deux puces qui ouvrent chacune leur feuille. Une
/// puce passe en noir quand son filtre n'est pas celui par défaut : on lit
/// d'un coup d'œil que les chiffres sont restreints.
///
/// Les bornes sont lues sur le cubit plutôt que recalculées : une seconde
/// formule dériverait du jour au lendemain et annoncerait une fenêtre
/// différente de celle des chiffres affichés juste en dessous. Les douze mois
/// glissants par défaut diffèrent de l'onglet Statistiques, qui n'affiche que
/// le mois courant : sans cette mention, les deux écrans sembleraient se
/// contredire.
class _Filters extends StatelessWidget {
  const _Filters({required this.onScope, required this.onPeriod});

  final VoidCallback onScope;
  final VoidCallback onPeriod;

  @override
  Widget build(BuildContext context) {
    // `watch` : chaque changement de filtre passe par un nouvel état.
    final cubit = context.watch<FinanceCubit>();
    final period = cubit.period;
    final from = cubit.from;
    final to = cubit.to;
    String monthYear(DateTime d) => DateFormat('MMM y').format(d);
    final periodLabel = switch ((period.year, period.month)) {
      (final int year, null) => 'finance_page.year_label'.tr(
        namedArgs: {'year': '$year'},
      ),
      (final int year, final int month) => toBeginningOfSentenceCase(
        monthYear(DateTime(year, month)),
      ),
      _ when from != null && to != null => 'finance_page.range'.tr(
        namedArgs: {'from': monthYear(from), 'to': monthYear(to)},
      ),
      _ => 'stats.period'.tr(),
    };
    final scopeLabel = cubit.scope.label;
    return Row(
      children: [
        Flexible(
          child: _FilterChip(
            icon: LucideIcons.building2,
            label: scopeLabel ?? 'finance_page.whole_portfolio'.tr(),
            active: scopeLabel != null,
            onTap: onScope,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: _FilterChip(
            icon: LucideIcons.calendarRange,
            label: periodLabel,
            active: !period.isRolling,
            onTap: onPeriod,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = active ? t.primaryForeground : t.foreground;
    return Material(
      color: active ? t.primary : t.surface,
      shape: StadiumBorder(
        side: active ? BorderSide.none : BorderSide(color: t.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelLarge!.copyWith(color: fg),
                ),
              ),
              const SizedBox(width: 4),
              Icon(LucideIcons.chevronDown, size: 16, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Squelette à la forme du contenu : la page ne saute pas à l'arrivée des
/// chiffres.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerEffect(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            LoadingShimmer(height: 150, radius: AppRadius.lg),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LoadingShimmer(height: 132, radius: AppRadius.lg),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: LoadingShimmer(height: 132, radius: AppRadius.lg),
                ),
              ],
            ),
            SizedBox(height: 10),
            LoadingShimmer(height: 110, radius: AppRadius.lg),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.overview});

  final FinanceOverviewModel overview;

  @override
  Widget build(BuildContext context) {
    final summary = overview.summary;
    final isLoss = summary.beneficeNet < 0;
    final period = context.read<FinanceCubit>().period;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<FinanceCubit>().load(),
          context.read<ExpenseCubit>().refresh(),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          HeroMetric(
            label: 'finance_page.net_profit'.tr(),
            value: CurrencyFormatter.format(summary.beneficeNet),
            loss: isLoss,
            note: isLoss ? 'finance_page.period_loss'.tr() : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'finance_page.gross_revenue'.tr(),
                  value: CurrencyFormatter.short(summary.caBrut),
                  icon: LucideIcons.trendingUp,
                  surface: StatSurface.sand,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricTile(
                  label: 'finance_page.expenses'.tr(),
                  value: CurrencyFormatter.short(summary.depenses),
                  icon: LucideIcons.trendingDown,
                  // Mention et non tuile : la commission est déjà dans les
                  // dépenses, une tuile à côté se lirait comme une charge de
                  // plus. Absente sans apporteur sur la période.
                  note: summary.commissions > 0
                      ? 'finance.including_commissions'.tr(
                          namedArgs: {
                            'amount': CurrencyFormatter.short(
                              summary.commissions,
                            ),
                          },
                        )
                      : null,
                ),
              ),
            ],
          ),
          // Masquée à zéro : la plupart des périodes n'ont aucun départ
          // anticipé, et une tuile vide ferait croire à un manque.
          if (summary.remboursements > 0) ...[
            const SizedBox(height: 10),
            MetricTile(
              label: 'finance.refunds'.tr(),
              value: CurrencyFormatter.short(summary.remboursements),
              icon: LucideIcons.undo2,
              height: 108,
            ),
          ],
          const SizedBox(height: 10),
          StatsRow(
            tauxOccupation: summary.tauxOccupation,
            reservations: summary.reservations,
            moyenSejour: summary.moyenSejour,
          ),
          // Sur un mois seul, la courbe n'aurait qu'un point : le CA brut
          // ci-dessus dit déjà tout.
          if (period.month == null) ...[
            const SizedBox(height: 16),
            Section(
              title: 'finance_page.monthly_revenue'.tr(),
              icon: LucideIcons.chartLine,
              child: overview.revenuePoints.isEmpty
                  ? EmptyState(
                      message: 'finance_page.no_revenue'.tr(),
                      icon: LucideIcons.chartLine,
                    )
                  : RevenueChart(
                      points: overview.revenuePoints,
                      year: period.year,
                    ),
            ),
          ],
          const SizedBox(height: 16),
          BlocBuilder<ExpenseCubit, ExpenseState>(
            builder: (context, state) => ExpenseBreakdownCard(
              categories: state is ExpenseLoaded
                  ? ExpenseCategoryModel.fromSummary(state.summary)
                  : const [],
              onExport: () {
                AppToast.info(
                  'finance_page.export_from_history'.tr(),
                  context: context,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
