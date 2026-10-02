import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
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
import '../../../residence/data/models/residence_model.dart';
import '../../../residence/data/repositories/residence_repository.dart';
import '../widgets/finance/finance_app_bar.dart';
import '../widgets/finance/finance_period_sheet.dart';
import '../widgets/finance/finance_residence_sheet.dart';
import '../widgets/finance/revenue_chart.dart';
import '../widgets/finance/stats_row.dart';

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
              filters: ExpenseFilters(from: bounds.from, to: bounds.to),
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
  String? _scopeLabel;

  @override
  void didPopNext() {
    context.read<FinanceCubit>().load();
    context.read<ExpenseCubit>().refresh();
  }

  Future<void> _pickScope() async {
    final cubit = context.read<FinanceCubit>();

    List<ResidenceModel> residences;
    try {
      residences = await sl<ResidenceRepository>().getAllResidences();
    } on AppFailure catch (f) {
      AppToast.error(f.userMessage);
      return;
    }

    if (!mounted) return;

    final selection = await FinanceResidenceSheet.show(
      context,
      residences: residences,
      selectedId: cubit.residenceId,
    );

    if (selection == null || !mounted) return;

    setState(() {
      _scopeLabel = selection.residenceId == null
          ? null
          : residences.firstWhere((r) => r.id == selection.residenceId).name;
    });

    await cubit.filterByResidence(selection.residenceId);

    if (!mounted) return;

    final expenses = context.read<ExpenseCubit>();
    await expenses.applyFilters(
      selection.residenceId == null
          ? expenses.filters.copyWith(clearResidence: true)
          : expenses.filters.copyWith(residenceId: selection.residenceId),
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
      appBar: FinanceAppBar(onFilterTap: _pickScope, scopeLabel: _scopeLabel),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hors de la liste : la période reste lisible, et modifiable,
          // pendant le chargement comme après une erreur.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _PeriodHeader(onChange: _pickPeriod),
          ),
          Expanded(
            child: BlocBuilder<FinanceCubit, FinanceState>(
              builder: (context, state) => switch (state) {
                FinanceInitial() ||
                FinanceLoading() => const Center(child: AppLoader()),
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

/// Période couverte par le relevé, et le bouton qui la change.
///
/// Les bornes sont lues sur le cubit plutôt que recalculées : une seconde
/// formule dériverait du jour au lendemain et annoncerait une fenêtre
/// différente de celle des chiffres affichés juste en dessous.
///
/// Annoncée avant les montants : les douze mois glissants par défaut diffèrent
/// de l'onglet Statistiques, qui n'affiche que le mois courant. Le même
/// `ca_brut` y prend deux valeurs, et sans cette mention les deux écrans
/// semblent se contredire.
class _PeriodHeader extends StatelessWidget {
  const _PeriodHeader({required this.onChange});

  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    // `watch` : chaque changement de période passe par un nouvel état.
    final cubit = context.watch<FinanceCubit>();
    final period = cubit.period;
    final from = cubit.from;
    final to = cubit.to;

    // Nom du mois dans la langue de l'application ; le français l'écrit en
    // minuscule, d'où la majuscule ajoutée en tête de libellé.
    String monthYear(DateTime d) => DateFormat('MMMM y').format(d);

    final label = switch ((period.year, period.month)) {
      (final int year, null) => 'finance_page.year_label'.tr(
        namedArgs: {'year': '$year'},
      ),
      (final int year, final int month) => toBeginningOfSentenceCase(
        monthYear(DateTime(year, month)),
      ),
      _ when from != null && to != null => 'finance_page.range'.tr(
        namedArgs: {'from': monthYear(from), 'to': monthYear(to)},
      ),
      _ => '',
    };

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('stats.period'.tr(), style: context.text.bodySmall),
              Text(
                label,
                style: context.text.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        AppButton(
          label: 'stats.change'.tr(),
          icon: LucideIcons.calendarRange,
          // Période restreinte : le bouton passe en noir, comme celui du
          // périmètre, pour qu'on lise que le relevé n'est pas celui par
          // défaut.
          variant: period.isRolling
              ? AppButtonVariant.secondary
              : AppButtonVariant.primary,
          size: AppButtonSize.sm,
          onPressed: onChange,
        ),
      ],
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          StatTile(
            label: 'finance_page.net_profit'.tr(),
            value: CurrencyFormatter.format(summary.beneficeNet),
            icon: LucideIcons.wallet,
            accent: isLoss ? AppAccent.red : AppAccent.green,
            note: isLoss ? 'finance_page.period_loss'.tr() : null,
            noteTone: isLoss ? StatNoteTone.down : null,
          ),
          const SizedBox(height: 12),
          StatGrid(
            children: [
              StatTile(
                label: 'finance_page.gross_revenue'.tr(),
                value: CurrencyFormatter.short(summary.caBrut),
                icon: LucideIcons.trendingUp,
                accent: AppAccent.green,
              ),
              StatTile(
                label: 'finance_page.expenses'.tr(),
                value: CurrencyFormatter.short(summary.depenses),
                icon: LucideIcons.trendingDown,
                accent: AppAccent.red,
              ),
              // Masquées à zéro : la plupart des périodes n'ont aucun départ
              // anticipé ni apporteur, et une tuile vide ferait croire à un
              // manque.
              if (summary.remboursements > 0)
                StatTile(
                  label: 'finance.refunds'.tr(),
                  value: CurrencyFormatter.short(summary.remboursements),
                  icon: LucideIcons.undo2,
                  accent: AppAccent.amber,
                ),
              if (summary.commissions > 0)
                StatTile(
                  label: 'finance.commissions'.tr(),
                  value: CurrencyFormatter.short(summary.commissions),
                  icon: LucideIcons.handshake,
                  accent: AppAccent.blue,
                ),
            ],
          ),
          const SizedBox(height: 12),
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
