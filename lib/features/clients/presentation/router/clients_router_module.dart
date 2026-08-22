import 'package:auto_route/auto_route.dart';

import 'package:resi_africa/core/custom_transition_builders.dart';

import 'clients_router_module.gr.dart';

// dart run build_runner build --delete-conflicting-outputs
@AutoRouterConfig(
  generateForDir: ['lib/features/clients/presentation/screens'],
  replaceInRouteName: 'Screen,Route',
)
class ClientsRouterModule extends RootStackRouter {
  @override
  RouteType get defaultRouteType =>
      RouteType.custom(transitionsBuilder: customTransitionBuilder);

  @override
  List<AutoRoute> get routes => [AutoRoute(page: ClientsRoute.page)];
}
