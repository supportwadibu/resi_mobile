import 'package:auto_route/auto_route.dart';
import 'package:resi_africa/core/custom_transition_builders.dart';
import 'subscription_router_module.gr.dart';

@AutoRouterConfig(
  generateForDir: ['lib/features/subscription/presentation/screens'],
  replaceInRouteName: 'Screen,Route',
)
class SubscriptionRouterModule extends RootStackRouter {
  @override
  RouteType get defaultRouteType =>
      RouteType.custom(transitionsBuilder: customTransitionBuilder);

  @override
  List<AutoRoute> get routes => [AutoRoute(page: SubscriptionPlansRoute.page)];
}
