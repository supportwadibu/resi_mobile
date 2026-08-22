import 'package:auto_route/auto_route.dart';
import 'package:resi_africa/core/custom_transition_builders.dart';
import 'home_router_module.gr.dart';

@AutoRouterConfig(
  generateForDir: ['lib/features/home/presentation/screens'],
  replaceInRouteName: 'Screen,Route',
)
class HomeRouterModule extends RootStackRouter {
  @override
  RouteType get defaultRouteType =>
      RouteType.custom(transitionsBuilder: customTransitionBuilder);

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: HomeRoute.page, initial: true),
  ];
}
