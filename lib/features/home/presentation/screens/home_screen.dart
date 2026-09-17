import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/router/role_guard.dart';
import '../../../../core/session/session_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../property/business_logic/property_cubit.dart';
import '../../business_logic/home_stats_cubit.dart';
import '../../../auth/presentation/widgets/profile_completion_banner.dart';
import '../../../reservation/presentation/widgets/create/reservation_mode_sheet.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../../shared/widgets/floating_action_card.dart';
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

  static const _features = [
    FloatingFeature(
      icon: FontAwesomeIcons.house,
      label: 'Ajouter un bien',
      action: 'add_property',
    ),
    FloatingFeature(
      icon: FontAwesomeIcons.calendarPlus,
      label: 'Nouvelle réservation',
      action: 'add_reservation',
    ),
    FloatingFeature(
      icon: FontAwesomeIcons.userPlus,
      label: 'Nouveau client',
      action: 'add_client',
    ),
    FloatingFeature(
      icon: FontAwesomeIcons.fileInvoiceDollar,
      label: 'Nouvelle dépense',
      action: 'add_expense',
    ),
  ];

  /// Créations offertes au rôle courant. Le menu, ses animations et son
  /// ancrage ne changent pas : seule la liste rendue est plus courte.
  ///
  /// Le rôle se lit sur la session, comme partout ailleurs dans le projet :
  /// l'état de l'`AuthCubit` ne le porte pas, et il doit rester lisible sans
  /// reconnexion après un redémarrage.
  List<FloatingFeature> get _visibleFeatures {
    final visible = featuresForRole(
      sl<SessionRole>().value,
      _features.map((f) => f.action).toList(),
    );
    return _features.where((f) => visible.contains(f.action)).toList();
  }

  @override
  void initState() {
    super.initState();
    _menuCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _menuScale = CurvedAnimation(parent: _menuCtrl, curve: Curves.easeOutBack);
    _menuFade = CurvedAnimation(parent: _menuCtrl, curve: Curves.easeOut);
    _menuSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _menuCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _menuCtrl.dispose();
    super.dispose();
  }

  void _openMenu() {
    setState(() => _menuOpen = true);
    _menuCtrl.forward();
  }

  void _closeMenu() {
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
        await context.router.push(AddPropertyRoute());
        if (mounted) _showProperties();
      case 'add_reservation':
        final mode = await showReservationModeSheet(context);
        if (mode != null && mounted) {
          if (!context.mounted) return;
          context.router.push(AddReservationRoute(mode: mode));
        }
      case 'add_expense':
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
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          SafeArea(
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
                child: ColoredBox(color: Colors.black.withOpacity(0.15)),
              ),
            ),

          Positioned(
            bottom: 16 + 90,
            right: 24,
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
                      features: _visibleFeatures,
                      onSelect: _handleAdd,
                      onDismiss: _closeMenu,
                    ),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: AppBottomNav(
              currentIndex: _currentIndex,
              isMenuOpen: _menuOpen,
              onMenuToggle: (open) => open ? _openMenu() : _closeMenu(),
              onTap: (i) {
                if (_menuOpen) _closeMenu();
                setState(() => _currentIndex = i);
              },
            ),
          ),
        ],
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
