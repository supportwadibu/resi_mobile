import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/error/failures.dart';
import '../../../expense/business_logic/expense_cubit.dart';
import '../../../expense/business_logic/expense_state.dart';
import '../../../expense/data/models/expense_category_model.dart';
import '../../../expense/presentation/widgets/stats/expense_breakdown_card.dart';
import '../../business_logic/finance_cubit.dart';
import '../../business_logic/finance_state.dart';
import '../../data/models/finance/finance_overview_model.dart';
import '../../../residence/data/models/residence_model.dart';
import '../../../residence/data/repositories/residence_repository.dart';
import '../widgets/finance/finance_app_bar.dart';
import '../widgets/finance/finance_residence_sheet.dart';
import '../widgets/finance/finance_summary_card.dart';
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
        BlocProvider(create: (_) => sl<ExpenseCubit>()..load()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: FinanceAppBar(onFilterTap: _pickScope, scopeLabel: _scopeLabel),
      body: BlocBuilder<FinanceCubit, FinanceState>(
        builder: (context, state) => switch (state) {
          FinanceInitial() ||
          FinanceLoading() => const Center(child: CircularProgressIndicator()),
          FinanceError(:final message) => _ErrorView(
            message: message,
            onRetry: () => context.read<FinanceCubit>().load(),
          ),
          FinanceLoaded(:final overview) => _Content(overview: overview),
        },
      ),
    );
  }
}

/// Période couverte par le relevé, telle que le cubit l'a demandée.
///
/// Lue sur le cubit plutôt que recalculée : une seconde formule dériverait du
/// jour au lendemain et annoncerait une fenêtre différente de celle des
/// chiffres affichés juste en dessous.
class _PeriodLabel extends StatelessWidget {
  const _PeriodLabel();

  static const _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceCubit>();
    final from = cubit.from;
    final to = cubit.to;

    if (from == null || to == null) return const SizedBox.shrink();

    String label(DateTime d) => '${_months[d.month - 1]} ${d.year}';

    return Text(
      'Du ${label(from)} à ${label(to)}',
      style: AppTextStyles.labelSmall,
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.overview});

  final FinanceOverviewModel overview;

  @override
  Widget build(BuildContext context) {
    final summary = overview.summary;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<FinanceCubit>().load(),
          context.read<ExpenseCubit>().refresh(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // La période est annoncée avant les montants : ce relevé porte sur
            // douze mois glissants, là où l'onglet Statistiques n'affiche que
            // le mois courant. Le même `ca_brut` y prend deux valeurs, et sans
            // cette mention les deux écrans semblent se contredire.
            const _PeriodLabel(),
            const SizedBox(height: 10),
            FinanceSummaryCard(
              label: 'CA Brut',
              amount: summary.caBrut,
              valueStyle: AppTextStyles.valueMedium,
            ),
            const SizedBox(height: 12),
            FinanceSummaryCard(
              label: 'Dépenses',
              amount: summary.depenses,
              valueStyle: AppTextStyles.valueMedium,
              trailing: const Icon(
                Icons.arrow_downward_rounded,
                color: AppColors.red,
                size: 18,
              ),
            ),
            const SizedBox(height: 12),
            FinanceSummaryCard(
              label: 'Bénéfice Net',
              amount: summary.beneficeNet,
              valueStyle: AppTextStyles.valueLarge,
              trailing: summary.beneficeNet < 0
                  ? const Icon(
                      Icons.trending_down_rounded,
                      color: AppColors.red,
                      size: 18,
                    )
                  : null,
            ),
            // Masquée à zéro : la plupart des périodes n'ont aucun départ
            // anticipé, et une carte vide ferait croire à un manque.
            if (summary.remboursements > 0) ...[
              const SizedBox(height: 12),
              FinanceSummaryCard(
                label: 'finance.refunds'.tr(),
                amount: summary.remboursements,
                valueStyle: AppTextStyles.valueMedium,
              ),
            ],
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: overview.revenuePoints.isEmpty
                  ? _Placeholder(message: 'Aucun revenu sur la période.')
                  : RevenueChart(points: overview.revenuePoints),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: StatsRow(
                tauxOccupation: summary.tauxOccupation,
                reservations: summary.reservations,
                moyenSejour: summary.moyenSejour,
              ),
            ),
            const SizedBox(height: 24),
            BlocBuilder<ExpenseCubit, ExpenseState>(
              builder: (context, state) => ExpenseBreakdownCard(
                categories: state is ExpenseLoaded
                    ? ExpenseCategoryModel.fromSummary(state.summary)
                    : const [],
                onExport: () {
                  AppToast.info(
                    'Export disponible depuis l’historique des dépenses',
                    context: context,
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
