import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../property/business_logic/property_cubit.dart';
import '../../../property/business_logic/property_state.dart';
import '../../business_logic/expense_cubit.dart';
import '../../business_logic/expense_state.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/services/expense_pdf_service.dart';
import '../widgets/home/expense_filter_bar.dart';
import '../widgets/home/expense_filter_sheet.dart';
import '../widgets/home/expense_header.dart';
import '../widgets/home/expense_list.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

    AppToast.success('Dépense supprimée');
  }

  /// Exporte l'ensemble des dépenses filtrées, et non la seule page affichée.
  Future<void> _export(ExpenseLoaded state) async {
    if (_isExporting) return;

    final filters = state.filters;
    setState(() => _isExporting = true);

    try {
      final expenses = await sl<ExpenseRepository>().getAllExpenses(
        propertyId: filters.propertyId,
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
      AppToast.error('L’export a échoué. Réessayez.');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Décrit le périmètre exporté, pour l'en-tête du document.
  String? _scopeLabel(ExpenseLoaded state) {
    final filters = state.filters;
    if (filters.isEmpty) return null;

    final parts = <String>[];
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

    return parts.isEmpty ? 'Sélection filtrée' : parts.join(' · ');
  }

  /// Période couverte par les filtres, ou `null` quand aucune borne n'est
  /// posée — le total porte alors sur tout l'historique.
  String? _periodLabel(ExpenseFilters filters) {
    final from = filters.from;
    final to = filters.to;
    if (from == null && to == null) return null;

    final format = DateFormat('d MMM yyyy', 'fr');
    if (from != null && to != null) {
      return 'Du ${format.format(from)} au ${format.format(to)}';
    }
    return from != null
        ? 'Depuis le ${format.format(from)}'
        : 'Jusqu’au ${format.format(to!)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              // Le rechargement est pris en charge par `didPopNext` : inutile
              // de le déclencher aussi depuis le bouton d'ajout, ce qui
              // lancerait deux requêtes pour un même retour.
              child: ExpenseHeader(),
            ),

            const SizedBox(height: 20),

            // Le total ouvre l'écran : c'est le chiffre recherché, et le
            // placer sous la liste obligeait à faire défiler tout le relevé
            // pour le lire.
            BlocBuilder<ExpenseCubit, ExpenseState>(
              // Le total vient du serveur : il porte sur l'ensemble des
              // dépenses filtrées, pas seulement sur les pages chargées.
              builder: (context, state) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ExpenseTotal(
                  total: state is ExpenseLoaded ? state.summary.total : 0,
                  count: state is ExpenseLoaded ? state.summary.count : 0,
                  periodLabel: state is ExpenseLoaded
                      ? _periodLabel(state.filters)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 14),

            BlocBuilder<ExpenseCubit, ExpenseState>(
              builder: (context, state) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ExpenseFilterBar(
                  activeCount: state is ExpenseLoaded
                      ? state.filters.activeCount
                      : 0,
                  onTap: _openFilters,
                  onClear: state is ExpenseLoaded && !state.filters.isEmpty
                      ? () => context.read<ExpenseCubit>().clearFilters()
                      : null,
                  onExport: state is ExpenseLoaded && state.items.isNotEmpty
                      ? () => _export(state)
                      : null,
                  isExporting: _isExporting,
                ),
              ),
            ),

            const SizedBox(height: 4),

            Expanded(
              child: BlocBuilder<ExpenseCubit, ExpenseState>(
                builder: (context, state) => switch (state) {
                  ExpenseInitial() || ExpenseLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  ExpenseError(:final message) => _ErrorView(
                    message: message,
                    onRetry: () => context.read<ExpenseCubit>().load(),
                  ),
                  ExpenseLoaded(:final items) when items.isEmpty => _EmptyView(
                    isFiltered: !state.filters.isEmpty,
                  ),
                  ExpenseLoaded(:final items) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({this.isFiltered = false});

  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 26,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'Aucune dépense pour ces filtres'
                  : 'Aucune dépense enregistrée',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 6),
            Text(
              // Un écran vide oriente vers l'action suivante plutôt que de
              // constater le vide.
              isFiltered
                  ? 'Élargissez la période ou changez de catégorie.'
                  : 'Ajoutez vos charges pour suivre ce que vos biens vous coûtent.',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium,
            ),
          ],
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
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.errorBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 26,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelMedium,
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.grey200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
