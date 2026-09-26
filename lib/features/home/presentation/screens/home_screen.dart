import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/role_guard.dart';
import '../../../../core/session/session_role.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../property/business_logic/property_cubit.dart';
import '../../business_logic/home_stats_cubit.dart';
import '../../../auth/presentation/widgets/profile_completion_banner.dart';
import '../../../reservation/presentation/widgets/create/reservation_mode_sheet.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../subscription/business_logic/plan_cubit.dart';
import '../../../subscription/presentation/widgets/plan_gate.dart';
import '../../../subscription/presentation/widgets/plan_style.dart';
import '../widgets/tabs/home_tab.dart';
import '../widgets/tabs/property_tab.dart';
import '../widgets/tabs/reservation_tab.dart';
import '../widgets/tabs/stats_tab.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Création proposée par le bouton « + ».
class _CreateAction {
  const _CreateAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.action,
  });

  final IconData icon;
  final String label;
  final String description;
  final String action;
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  /// Donne accès aux onglets pour relire les chiffres de l'accueil : le cubit
  /// qui les porte est fourni sous `build`, donc hors de portée d'ici.
  final _tabsKey = GlobalKey<_HomeTabsState>();

  /// Icônes de section : une création porte l'icône de la section qu'elle
  /// alimente, comme partout ailleurs dans l'application.
  static const _actions = [
    _CreateAction(
      icon: AppSectionIcons.properties,
      label: 'Ajouter un bien',
      description: 'Publier un logement',
      action: 'add_property',
    ),
    _CreateAction(
      icon: AppSectionIcons.bookings,
      label: 'Nouvelle réservation',
      description: 'Au comptoir ou pour un client',
      action: 'add_reservation',
    ),
    _CreateAction(
      icon: AppSectionIcons.clients,
      label: 'Nouveau client',
      description: 'Ajouter une fiche au carnet',
      action: 'add_client',
    ),
    _CreateAction(
      icon: AppSectionIcons.expenses,
      label: 'Nouvelle dépense',
      description: 'Une charge liée à un bien',
      action: 'add_expense',
    ),
  ];

  /// Créations offertes au rôle courant.
  ///
  /// Le rôle se lit sur la session, comme partout ailleurs dans le projet :
  /// l'état de l'`AuthCubit` ne le porte pas, et il doit rester lisible sans
  /// reconnexion après un redémarrage.
  List<_CreateAction> get _visibleActions {
    final visible = featuresForRole(
      sl<SessionRole>().value,
      _actions.map((a) => a.action).toList(),
    );
    return _actions.where((a) => visible.contains(a.action)).toList();
  }

  @override
  void initState() {
    super.initState();
    // L'accueil est la porte d'entrée après la connexion : l'accès y est relu,
    // et un compte inactif est aussitôt redirigé par l'écoute de `App`.
    sl<PlanCubit>().refresh();
  }

  static const _propertyTabIndex = 2;

  void _showProperties() {
    if (_currentIndex == _propertyTabIndex) return;
    setState(() => _currentIndex = _propertyTabIndex);
  }

  Future<void> _openCreateSheet() async {
    final action = await showAppSheet<String>(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: 'Créer',
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            for (final item in _visibleActions)
              AppSheetAction(
                icon: item.icon,
                label: item.label,
                description: item.description,
                onTap: () => Navigator.of(sheetContext).pop(item.action),
              ),
          ],
        ),
      ),
    );
    if (action != null && mounted) await _handleAdd(action);
  }

  Future<void> _handleAdd(String action) async {
    switch (action) {
      case 'add_property':
        await context.router.push(AddPropertyRoute());
        if (mounted) _showProperties();
      case 'add_reservation':
        final mode = await showReservationModeSheet(context);
        if (mode != null && mounted) {
          if (!context.mounted) return;
          context.router.push(AddReservationRoute(mode: mode));
        }
      case 'add_expense':
        if (!ensureFullPlan(context, PremiumFeature.expenses)) return;
        // Attendu, puis les chiffres relus : une dépense change le bénéfice
        // net affiché sur l'accueil, qui reste monté sous la pile.
        await context.router.push(AddExpenseRoute());
        if (mounted) _reloadStats();
      case 'add_client':
        context.router.push(const AddClientRoute());
    }
  }

  /// Relit la rangée de l'accueil.
  ///
  /// Le cubit est fourni sous `build`, hors de portée de `context.read` ici :
  /// la clé donne accès à l'état qui le détient.
  void _reloadStats() => _tabsKey.currentState?.reloadStats();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ProfileCompletionBanner(),
            Expanded(
              child: MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<PropertyCubit>()..load()),
                  // Fourni ici et non dans l'onglet : celui-ci reste monté
                  // dans l'`IndexedStack`, et un cubit local ne serait
                  // jamais rechargé après l'ajout d'un bien ou d'une
                  // dépense.
                  BlocProvider(create: (_) => sl<HomeStatsCubit>()..load()),
                ],
                child: _HomeTabs(
                  key: _tabsKey,
                  currentIndex: _currentIndex,
                  onSeeAllProperties: _showProperties,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _visibleActions.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: _openCreateSheet,
              tooltip: 'Créer',
              child: const Icon(LucideIcons.plus, size: 22),
            ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// Les quatre onglets, et le rafraîchissement des chiffres de l'accueil.
///
/// Les onglets restent montés dans l'`IndexedStack` : sans ce rechargement au
/// retour, la rangée de l'accueil garderait les chiffres d'avant la saisie
/// d'un bien, d'une réservation ou d'une dépense.
class _HomeTabs extends StatefulWidget {
  const _HomeTabs({
    super.key,
    required this.currentIndex,
    this.onSeeAllProperties,
  });

  final int currentIndex;
  final VoidCallback? onSeeAllProperties;

  @override
  State<_HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<_HomeTabs> {
  static const _homeTabIndex = 0;

  /// Relit les chiffres de l'accueil, appelée au retour d'un écran de saisie.
  void reloadStats() => context.read<HomeStatsCubit>().load();

  @override
  void didUpdateWidget(_HomeTabs oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Au retour sur l'accueil seulement : recharger à chaque changement
    // d'onglet lancerait trois requêtes pour un aller-retour vers les
    // statistiques, qui ne touchent à rien.
    final cameBack =
        widget.currentIndex == _homeTabIndex &&
        oldWidget.currentIndex != _homeTabIndex;

    if (cameBack) context.read<HomeStatsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.currentIndex,
      children: [
        HomeTab(onSeeAllProperties: widget.onSeeAllProperties),
        const ReservationTab(),
        const PropertyTab(),
        const StatsTab(),
      ],
    );
  }
}
