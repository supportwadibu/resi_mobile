import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/offline/offline_prefetcher.dart';
import '../../../../core/router/role_guard.dart';
import '../../../../core/session/session_role.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/resi_tokens.dart';
import '../../../property/business_logic/property_cubit.dart';
import '../../business_logic/home_stats_cubit.dart';
import '../../../auth/presentation/widgets/profile_completion_banner.dart';
import '../../../feedback/presentation/widgets/feedback_sheet.dart';
import '../../../reservation/presentation/widgets/create/reservation_mode_sheet.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/floating_action_card.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../reservation/presentation/widgets/sync_status_banner.dart';
import '../../../subscription/business_logic/plan_cubit.dart';
import '../../../subscription/presentation/widgets/plan_gate.dart';
import '../../../subscription/presentation/widgets/plan_style.dart';
import '../widgets/tabs/home_tab.dart';
import '../widgets/tabs/property_tab.dart';
import '../widgets/tabs/reservation_tab.dart';
import '../widgets/tabs/stats_tab.dart';
import 'package:resi_africa/shared/utils/ensure_online.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  bool _menuOpen = false;

  /// Donne accès aux onglets pour relire les chiffres de l'accueil : le cubit
  /// qui les porte est fourni sous `build`, donc hors de portée d'ici.
  final _tabsKey = GlobalKey<_HomeTabsState>();

  late final AnimationController _menuCtrl;
  late final Animation<double> _menuScale;
  late final Animation<double> _menuFade;
  late final Animation<Offset> _menuSlide;

  /// Icônes de section : une création porte l'icône de la section qu'elle
  /// alimente, comme partout ailleurs dans l'application.
  static const _actions = [
    FloatingFeature(
      icon: AppSectionIcons.properties,
      label: 'home_actions.add_property',
      description: 'home_actions.add_property_hint',
      action: 'add_property',
    ),
    FloatingFeature(
      icon: AppSectionIcons.bookings,
      label: 'home_actions.add_reservation',
      description: 'home_actions.add_reservation_hint',
      action: 'add_reservation',
    ),
    FloatingFeature(
      icon: AppSectionIcons.clients,
      label: 'home_actions.add_client',
      description: 'home_actions.add_client_hint',
      action: 'add_client',
    ),
    FloatingFeature(
      icon: AppSectionIcons.expenses,
      label: 'home_actions.add_expense',
      description: 'home_actions.add_expense_hint',
      action: 'add_expense',
    ),
    // Pas une création, mais une saisie comme les autres : la carte la garde
    // à portée de pouce depuis chaque onglet, là où l'accueil l'enterrait
    // sous la grille des biens.
    FloatingFeature(
      icon: AppSectionIcons.reviews,
      label: 'home_actions.feedback',
      description: 'home_actions.feedback_hint',
      action: 'feedback',
    ),
  ];

  /// Créations offertes au rôle courant.
  ///
  /// Le rôle se lit sur la session, comme partout ailleurs dans le projet :
  /// l'état de l'`AuthCubit` ne le porte pas, et il doit rester lisible sans
  /// reconnexion après un redémarrage.
  List<FloatingFeature> get _visibleActions {
    final visible = featuresForRole(
      sl<SessionRole>().value,
      _actions.map((a) => a.action).toList(),
    );
    return _actions.where((a) => visible.contains(a.action)).toList();
  }

  @override
  void initState() {
    super.initState();
    _menuCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    // Sans rebond, comme tout mouvement de l'application : la carte part de
    // 90 % et non de zéro, sinon ses libellés passeraient par des tailles
    // illisibles.
    final curve = CurvedAnimation(
      parent: _menuCtrl,
      curve: Curves.easeOutCubic,
    );
    _menuScale = Tween<double>(begin: 0.9, end: 1).animate(curve);
    _menuFade = curve;
    _menuSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curve);

    // L'accueil est la porte d'entrée après la connexion : l'accès y est relu,
    // et un compte inactif est aussitôt redirigé par l'écoute de `App`.
    sl<PlanCubit>().refresh();

    // Garnit le cache pour le mode hors ligne, en tâche de fond : l'accueil
    // est le premier écran ouvert en ligne après la connexion.
    unawaited(sl<OfflinePrefetcher>().run());
  }

  @override
  void dispose() {
    _menuCtrl.dispose();
    super.dispose();
  }

  void _toggleMenu() => _menuOpen ? _closeMenu() : _openMenu();

  void _openMenu() {
    setState(() => _menuOpen = true);
    _menuCtrl.forward();
  }

  void _closeMenu() {
    if (!_menuOpen) return;
    setState(() => _menuOpen = false);
    _menuCtrl.reverse();
  }

  static const _propertyTabIndex = 2;

  void _showProperties() {
    if (_currentIndex == _propertyTabIndex) return;
    setState(() => _currentIndex = _propertyTabIndex);
  }

  Future<void> _handleAdd(String action) async {
    _closeMenu();
    switch (action) {
      case 'add_property':
        if (!await ensureOnline(context) || !mounted) return;
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
      case 'feedback':
        if (!await ensureOnline(context) || !mounted) return;
        showFeedbackSheet(context);
    }
  }

  /// Relit la rangée de l'accueil.
  ///
  /// Le cubit est fourni sous `build`, hors de portée de `context.read` ici :
  /// la clé donne accès à l'état qui le détient.
  void _reloadStats() => _tabsKey.currentState?.reloadStats();

  @override
  Widget build(BuildContext context) {
    final actions = _visibleActions;
    // Le retour système referme d'abord le menu, sans quitter l'accueil.
    return PopScope(
      canPop: !_menuOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeMenu();
      },
      child: Scaffold(
        // Le contenu défile sous la barre flottante, visible à travers son
        // fond translucide.
        extendBody: true,
        body: Builder(
          // Lu sous le `Scaffold` : c'est là que la hauteur de la barre est
          // reportée dans la marge basse.
          builder: (bodyContext) {
            final barInset = MediaQuery.paddingOf(bodyContext).bottom;
            return Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      const ProfileCompletionBanner(),
                      // Au-dessus des onglets : chacun peut afficher des
                      // données gardées sur l'appareil, et la saisie en file
                      // concerne tout le parc, pas la seule liste des séjours.
                      const OfflineBanner(),
                      const SyncStatusBanner(),
                      Expanded(
                        child: MultiBlocProvider(
                          providers: [
                            BlocProvider(
                              create: (_) => sl<PropertyCubit>()..load(),
                            ),
                            // Fourni ici et non dans l'onglet : celui-ci reste
                            // monté dans l'`IndexedStack`, et un cubit local ne
                            // serait jamais rechargé après l'ajout d'un bien ou
                            // d'une dépense.
                            BlocProvider(
                              create: (_) => sl<HomeStatsCubit>()..load(),
                            ),
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
                if (_menuOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _closeMenu,
                      behavior: HitTestBehavior.opaque,
                      child: ColoredBox(
                        color: context.tokens.overlay.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: barInset + 8,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: IgnorePointer(
                      ignoring: !_menuOpen,
                      child: FadeTransition(
                        opacity: _menuFade,
                        child: SlideTransition(
                          position: _menuSlide,
                          child: ScaleTransition(
                            scale: _menuScale,
                            alignment: Alignment.bottomRight,
                            child: FloatingActionCard(
                              features: actions,
                              onSelect: _handleAdd,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          isMenuOpen: _menuOpen,
          onMenuToggle: actions.isEmpty ? null : _toggleMenu,
          onTap: (i) {
            _closeMenu();
            setState(() => _currentIndex = i);
          },
        ),
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
