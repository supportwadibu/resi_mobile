import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.gr.dart';
import 'core/session/session_role.dart';
import 'features/subscription/business_logic/plan_cubit.dart';
import 'features/subscription/business_logic/plan_state.dart';
import 'features/reservation/presentation/widgets/sync_result_listener.dart';
import 'features/subscription/data/models/plan_access.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatefulWidget {
  const App({super.key, required this.config});
  final AppConfig config;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  final _router = sl<AppRouter>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Un abonnement peut expirer ou être payé pendant que l'application dort :
  /// l'accès est relu à chaque retour au premier plan.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) sl<PlanCubit>().refresh();
  }

  /// Compte devenu inactif : l'écran des forfaits remplace l'application.
  ///
  /// Écouté ici, au-dessus de toutes les routes, parce que le refus peut
  /// survenir sur n'importe quel écran. Sans effet s'il est déjà affiché.
  /// Un gérant n'a rien à faire au forfait 3 000 F : tout son espace relève
  /// du forfait complet, et chaque écran lui opposerait un refus.
  static bool _isLockedOut(PlanAccess access) =>
      access == PlanAccess.inactive ||
      (access == PlanAccess.basic && sl<SessionRole>().value == 'gerant');

  void _onPlanChanged(BuildContext context, PlanState state) {
    if (_router.current.name == SubscriptionPlansRoute.name) return;
    _router.replaceAll([SubscriptionPlansRoute(blocking: true)]);
  }

  @override
  Widget build(BuildContext context) {
    // L'apparence est écoutée ici, au-dessus du routeur : un choix fait dans
    // le profil bascule toute la pile d'écrans d'un coup.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: sl<ThemeController>(),
      builder: (context, themeMode, _) => _buildApp(context, themeMode),
    );
  }

  Widget _buildApp(BuildContext context, ThemeMode themeMode) {
    // easy_localization ne touche pas à `Intl.defaultLocale` : sans cette
    // ligne, dates et montants resteraient dans la langue par défaut d'intl
    // pendant que les libellés passent à l'anglais. Posé ici, il suit aussi
    // un changement de langue, qui reconstruit ce widget.
    Intl.defaultLocale = context.locale.toLanguageTag();
    return MaterialApp.router(
      title: widget.config.appName,
      debugShowCheckedModeBanner: !widget.config.isProduction,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // `AutoRouteObserver` : permet aux écrans d'être prévenus quand ils
      // redeviennent visibles (`AutoRouteAwareStateMixin.didPopNext`), pour
      // rafraîchir des données modifiées entre-temps.
      routerConfig: _router.config(
        navigatorObservers: () => [AutoRouteObserver()],
      ),
      builder: (context, child) => BlocListener<PlanCubit, PlanState>(
        bloc: sl<PlanCubit>(),
        listenWhen: (_, current) => _isLockedOut(current.access),
        listener: _onPlanChanged,
        child: SyncResultListener(
          child: _LocaleRebuilder(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// Redessine tout l'écran quand la langue change, sans rien démonter.
///
/// La plupart des libellés appellent `tr()` sans `BuildContext` : ils ne
/// dépendent d'aucun widget hérité et ne seraient pas reconstruits — la langue
/// choisie dans le profil ne s'appliquerait qu'aux écrans ouverts ensuite.
/// `Localizations` ne publie la nouvelle langue qu'une fois ses traductions
/// chargées : c'est ce moment qu'on attend pour marquer chaque élément à
/// reconstruire. Une clé changée aurait le même effet visible, mais perdrait
/// l'onglet ouvert, les champs saisis et la pile de navigation.
class _LocaleRebuilder extends StatefulWidget {
  const _LocaleRebuilder({required this.child});

  final Widget child;

  @override
  State<_LocaleRebuilder> createState() => _LocaleRebuilderState();
}

class _LocaleRebuilderState extends State<_LocaleRebuilder> {
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_locale != null && _locale != locale) {
      void rebuild(Element element) {
        element.markNeedsBuild();
        element.visitChildren(rebuild);
      }

      (context as Element).visitChildren(rebuild);
    }
    _locale = locale;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
