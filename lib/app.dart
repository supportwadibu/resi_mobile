import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/di/service_locator.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class App extends StatefulWidget {
  const App({super.key, required this.config});
  final AppConfig config;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _router = sl<AppRouter>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: widget.config.appName,
      debugShowCheckedModeBanner: !widget.config.isProduction,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      // `AutoRouteObserver` : permet aux écrans d'être prévenus quand ils
      // redeviennent visibles (`AutoRouteAwareStateMixin.didPopNext`), pour
      // rafraîchir des données modifiées entre-temps.
      routerConfig: _router.config(
        navigatorObservers: () => [AutoRouteObserver()],
      ),
    );
  }
}
