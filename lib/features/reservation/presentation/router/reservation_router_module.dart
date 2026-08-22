import 'package:auto_route/auto_route.dart';
import 'package:resi_africa/core/custom_transition_builders.dart';
import 'reservation_router_module.gr.dart';

@AutoRouterConfig(
  generateForDir: ['lib/features/reservation/presentation/screens'],
  replaceInRouteName: 'Screen,Route',
)
class ReservationRouterModule extends RootStackRouter {
  @override
  RouteType get defaultRouteType =>
      RouteType.custom(transitionsBuilder: customTransitionBuilder);

  @override
  List<AutoRoute> get routes => [AutoRoute(page: ReservationRoute.page)];
}
