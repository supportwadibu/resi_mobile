import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import '../../../../core/theme/app_colors.dart';
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

  /// Index de l'onglet « Mes biens » dans l'`IndexedStack`.
  static const _propertyTabIndex = 2;

  /// Met l'onglet « Mes biens » en avant.
  void _showProperties() {
    if (_currentIndex == _propertyTabIndex) return;
    setState(() => _currentIndex = _propertyTabIndex);
  }

  Future<void> _handleAdd(String action) async {
    _closeMenu();
    switch (action) {
      case 'add_property':
        // Au retour du dépôt, l'onglet des biens est mis en avant : sans cela
        // l'utilisateur revenait sur l'accueil et devait chercher lui-même
        // l'annonce qu'il venait de créer.
        await context.router.push(const AddPropertyRoute());
        if (mounted) _showProperties();
      case 'add_reservation':
        // Le mode commande tout le formulaire — date verrouillée et séjour
        // « en cours » pour un check-in, date au choix sinon : il se demande
        // donc avant d'ouvrir l'écran, pas au milieu de la saisie.
        final mode = await showReservationModeSheet(context);
        if (mode != null && mounted) {
          if (!context.mounted) return;
          context.router.push(AddReservationRoute(mode: mode));
        }
      case 'add_expense':
        context.router.push(AddExpenseRoute());
      case 'add_client':
        context.router.push(const AddClientRoute());
    }
  }

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
                  child: IndexedStack(
                    index: _currentIndex,
                    children: [
                      HomeTab(onSeeAllProperties: _showProperties),
                      const ReservationTab(),
                      const PropertyTab(),
                      const StatsTab(),
                    ],
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
                      features: _features,
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
