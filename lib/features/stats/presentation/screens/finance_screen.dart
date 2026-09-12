import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
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
        // La ventilation par catégorie vient du même endpoint que l'historique.
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
  /// Nom de la résidence retenue, pour l’afficher dans la barre.
  ///
  /// Conservé ici et non dans le cubit : celui-ci ne connaît que
  /// l’identifiant, et lui faire porter un libellé d’affichage mêlerait la
  /// présentation à l’état métier.
  String? _scopeLabel;

  /// L'écran redevient visible : revenus et charges sont relus.
  ///
  /// Une dépense saisie depuis un autre écran change le bénéfice net affiché
  /// ici ; sans ce rechargement, le chiffre resterait celui d'avant.
  ///
  /// Le périmètre est conservé : il vit dans le cubit, que ce rechargement ne
  /// réinitialise pas.
  @override
  void didPopNext() {
    context.read<FinanceCubit>().load();
    context.read<ExpenseCubit>().refresh();
  }

  /// Ouvre le choix du périmètre, puis recharge si la sélection a changé.
  Future<void> _pickScope() async {
    final cubit = context.read<FinanceCubit>();
    final messenger = ScaffoldMessenger.of(context);

    List<ResidenceModel> residences;
    try {
      residences = await sl<ResidenceRepository>().getAllResidences();
    } on AppFailure catch (f) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(f.userMessage)));
      return;
    }

    if (!mounted) return;

    final selection = await showModalBottomSheet<FinanceScopeSelection>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FinanceResidenceSheet(
        residences: residences,
        selectedId: cubit.residenceId,
      ),
    );

    // `null` ici est une annulation, pas « tout le parc » : c’est la raison
    // d’être de l’enveloppe `FinanceScopeSelection`.
    if (selection == null || !mounted) return;

    setState(() {
      _scopeLabel = selection.residenceId == null
          ? null
          : residences
                .firstWhere((r) => r.id == selection.residenceId)
                .name;
    });

    await cubit.filterByResidence(selection.residenceId);

    if (!mounted) return;

    // La ventilation par catégorie suit le même périmètre : la carte
    // « Dépenses » et l’anneau juste en dessous viennent de deux endpoints
    // distincts, et les laisser divergents afficherait deux totaux
    // contradictoires sur la même page.
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
      appBar: FinanceAppBar(
        onFilterTap: _pickScope,
        scopeLabel: _scopeLabel,
      ),
      body: BlocBuilder<FinanceCubit, FinanceState>(
        builder: (context, state) => switch (state) {
          FinanceInitial() || FinanceLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
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
              // Une perte doit se lire comme telle : un bénéfice négatif sans
              // signal visuel passerait pour un gain.
              trailing: summary.beneficeNet < 0
                  ? const Icon(
                      Icons.trending_down_rounded,
                      color: AppColors.red,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: overview.revenuePoints.isEmpty
                  ? _Placeholder(
                      message: 'Aucun revenu sur la période.',
                    )
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Export disponible depuis l’historique des dépenses',
                      ),
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
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
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
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
