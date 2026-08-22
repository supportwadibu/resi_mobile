import 'package:auto_route/auto_route.dart';
import 'package:resi_africa/core/custom_transition_builders.dart';
import 'property_router_module.gr.dart';

// dart run build_runner build --delete-conflicting-outputs
@AutoRouterConfig(
  generateForDir: ['lib/features/property/presentation/screens'],
  replaceInRouteName: 'Screen,Route',
)
class PropertyRouterModule extends RootStackRouter {
  @override
  RouteType get defaultRouteType => RouteType.custom(
        transitionsBuilder: customTransitionBuilder,
      );

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: PropertyRoute.page),
        AutoRoute(page: PropertyDetailRoute.page),
      ];
}
