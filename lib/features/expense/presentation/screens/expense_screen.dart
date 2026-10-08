import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../property/business_logic/property_cubit.dart';
import '../../../property/business_logic/property_state.dart';
import '../../../../core/error/failures.dart';
import '../../../residence/data/models/residence_model.dart';
import '../../../residence/data/repositories/residence_repository.dart';
import '../../business_logic/expense_cubit.dart';
import '../../business_logic/expense_state.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/services/expense_pdf_service.dart';
import '../widgets/home/expense_filter_bar.dart';
import '../widgets/home/expense_filter_sheet.dart';
import '../widgets/home/expense_list.dart';
import '../widgets/home/expense_month_stepper.dart';
import '../widgets/home/expense_total.dart';

@RoutePage()
class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ExpenseCubit>()..load()),
        // Les biens alimentent la feuille de filtres.
        BlocProvider(create: (_) => sl<PropertyCubit>()..load()),
      ],
      child: const _ExpenseView(),
    );
  }
}

class _ExpenseView extends StatefulWidget {
  const _ExpenseView();

  @override
  State<_ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends State<_ExpenseView>
    with AutoRouteAwareStateMixin<_ExpenseView> {
  final _scrollController = ScrollController();
  bool _isExporting = false;

  /// Résidences proposées au filtre. Vide tant qu'elles ne sont pas lues, ou
  /// si la lecture échoue : la feuille reste utilisable sur les seuls biens.
  List<ResidenceModel> _residences = const [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadResidences();
  }

  Future<void> _loadResidences() async {
    try {
      final residences = await sl<ResidenceRepository>().getAllResidences();
      if (mounted) setState(() => _residences = residences);
    } on AppFailure {
      // Hors réseau ou rôle sans accès : le filtre par résidence manque, le
      // reste de l'écran n'en dépend pas.
    }
  }

  /// L'écran redevient visible : la liste est rechargée.
  ///
  /// Couvre tous les chemins de retour, y compris une dépense saisie depuis le
  /// raccourci de l'accueil — cet écran restant monté sous la pile, il
  /// afficherait sinon des données périmées.
  @override
  void didPopNext() {
    context.read<ExpenseCubit>().refresh();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Charge la page suivante à l'approche du bas, avant d'y arriver : la liste
  /// s'allonge sans que le défilement ne butte.
  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      context.read<ExpenseCubit>().loadMore();
    }
  }

  Future<void> _openFilters() async {
    final cubit = context.read<ExpenseCubit>();
    final propertyState = context.read<PropertyCubit>().state;

    final filters = await ExpenseFilterSheet.show(
      context,
      initial: cubit.filters,
      properties: propertyState is PropertyLoaded
          ? propertyState.items
          : const [],
      residences: _residences,
    );

    // `null` : la feuille a été fermée sans valider, les filtres ne bougent pas.
    if (filters != null) await cubit.applyFilters(filters);
  }

  /// Ouvre la dépense en modification.
  ///
  /// Le rechargement au retour est assuré par `didPopNext`, quel que soit le
  /// résultat : une modification annulée n'a rien changé, un rechargement de
  /// trop est sans conséquence.
  Future<void> _edit(ExpenseModel expense) async {
    await context.router.push<bool>(AddExpenseRoute(expense: expense));
  }

  Future<void> _delete(ExpenseModel expense) async {
    final error = await context.read<ExpenseCubit>().delete(expense.id);

    if (error != null) {
      AppToast.error(error);
      return;
    }

    AppToast.success('expense.deleted'.tr());
  }

  /// Exporte l'ensemble des dépenses filtrées, et non la seule page affichée.
  Future<void> _export(ExpenseLoaded state) async {
    if (_isExporting) return;

    final filters = state.filters;
    setState(() => _isExporting = true);

    try {
      final expenses = await sl<ExpenseRepository>().getAllExpenses(
        propertyId: filters.propertyId,
        residenceId: filters.residenceId,
        category: filters.category,
        from: filters.from,
        to: filters.to,
      );

      await const ExpensePdfService().share(
        expenses: expenses,
        summary: state.summary,
        scopeLabel: _scopeLabel(state),
      );
    } catch (e) {
      AppToast.error('expense.export_failed'.tr());
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Décrit le périmètre exporté, pour l'en-tête du document.
  ///
  /// La période y figure : un relevé du mois en cours exporté sans elle se
  /// lirait comme l'historique complet.
  String? _scopeLabel(ExpenseLoaded state) {
    final filters = state.filters;
    if (filters.isEmpty) return null;

    final parts = <String>[];
    if (filters.residenceId != null) {
      final match = _residences
          .where((r) => r.id == filters.residenceId)
          .firstOrNull;
      if (match != null) parts.add(match.name);
    }
    if (filters.propertyId != null) {
      final propertyState = context.read<PropertyCubit>().state;
      if (propertyState is PropertyLoaded) {
        final match = propertyState.items
            .where((p) => p.id == filters.propertyId)
            .firstOrNull;
        if (match != null) parts.add(match.title);
      }
    }
    if (filters.category != null) parts.add(filters.category!.label);
    if (_periodLabel(filters) case final period?) parts.add(period);

    return parts.isEmpty
        ? 'expense.filtered_selection'.tr()
        : parts.join(' · ');
  }

  /// Période couverte par les filtres, ou `null` quand aucune borne n'est
  /// posée — le total porte alors sur tout l'historique.
  String? _periodLabel(ExpenseFilters filters) {
    if (filters.month case final month?) {
      return toBeginningOfSentenceCase(
        DateFormat('MMMM yyyy', context.locale.toString()).format(month),
      );
    }

    final from = filters.from;
    final to = filters.to;
    if (from == null && to == null) return null;

    final format = DateFormat('d MMM yyyy');
    if (from != null && to != null) {
      return 'expense.range_between'.tr(
        namedArgs: {'from': format.format(from), 'to': format.format(to)},
      );
    }
    return from != null
        ? 'expense.range_from'.tr(args: [format.format(from)])
        : 'expense.range_until'.tr(args: [format.format(to!)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'expense.title'.tr(),
        actions: [
          // Le rechargement au retour est pris en charge par `didPopNext` :
          // inutile de le déclencher aussi ici, ce qui lancerait deux
          // requêtes pour un même retour.
          AppButton(
            label: 'common.add'.tr(),
            icon: LucideIcons.plus,
            size: AppButtonSize.sm,
            onPressed: () => context.router.push(AddExpenseRoute()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Le total ouvre l'écran : c'est le chiffre recherché, et le placer
          // sous la liste obligeait à faire défiler tout le relevé pour le
          // lire.
          BlocBuilder<ExpenseCubit, ExpenseState>(
            // Le total vient du serveur : il porte sur l'ensemble des
            // dépenses filtrées, pas seulement sur les pages chargées.
            builder: (context, state) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ExpenseTotal(
                total: state is ExpenseLoaded ? state.summary.total : 0,
                count: state is ExpenseLoaded ? state.summary.count : 0,
                // Un mois est déjà affiché par le sélecteur placé dessous.
                periodLabel:
                    state is ExpenseLoaded && state.filters.month == null
                    ? _periodLabel(state.filters)
                    : null,
              ),
            ),
          ),
          // Le mois se change d'un geste, sans ouvrir les filtres : c'est la
          // lecture la plus courante — « et le mois dernier ? ».
          BlocBuilder<ExpenseCubit, ExpenseState>(
            builder: (context, state) {
              final month = context.read<ExpenseCubit>().filters.month;
              if (month == null) return const SizedBox.shrink();

              final cubit = context.read<ExpenseCubit>();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ExpenseMonthStepper(
                  month: month,
                  onPrevious: () => cubit.shiftMonth(-1),
                  onNext: () => cubit.shiftMonth(1),
                ),
              );
            },
          ),
          BlocBuilder<ExpenseCubit, ExpenseState>(
            builder: (context, state) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: ExpenseFilterBar(
                activeCount: state is ExpenseLoaded
                    ? state.filters.activeCount
                    : 0,
                onTap: _openFilters,
                onClear: state is ExpenseLoaded && !state.filters.isDefault
                    ? () => context.read<ExpenseCubit>().clearFilters()
                    : null,
                onExport: state is ExpenseLoaded && state.items.isNotEmpty
                    ? () => _export(state)
                    : null,
                isExporting: _isExporting,
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<ExpenseCubit, ExpenseState>(
              // Une page qui ne remplit pas l'écran ne se fait jamais
              // défiler : la suivante est demandée dès qu'elle est posée.
              listener: (_, state) {
                if (state is ExpenseLoaded && !state.isLoadingMore) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _onScroll(),
                  );
                }
              },
              builder: (context, state) => switch (state) {
                ExpenseInitial() ||
                ExpenseLoading() => const SimpleListSkeleton(itemCount: 5),
                ExpenseError(:final message) => ErrorState(
                  message: message,
                  onRetry: () => context.read<ExpenseCubit>().load(),
                ),
                ExpenseLoaded(:final items) when items.isEmpty => EmptyState(
                  icon: AppSectionIcons.expenses,
                  title: state.filters.isDefault
                      ? 'expense.empty_month_title'.tr()
                      : 'expense.empty_filtered'.tr(),
                  // Un écran vide oriente vers l'action suivante plutôt que
                  // de constater le vide.
                  message: state.filters.isDefault
                      ? 'expense.empty_body'.tr()
                      : 'expense.empty_filtered_body'.tr(),
                ),
                ExpenseLoaded(:final items) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ExpenseList(
                    expenses: items,
                    controller: _scrollController,
                    isLoadingMore: state.isLoadingMore,
                    onEdit: _edit,
                    onDelete: _delete,
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}
