import 'package:auto_route/auto_route.dart';
import 'package:resi_africa/core/custom_transition_builders.dart';

@AutoRouterConfig(
  generateForDir: ['lib/features/auth/presentation/screens'],
  replaceInRouteName: 'Screen,Route',
)
class AuthRouterModule extends RootStackRouter {
  @override
  RouteType get defaultRouteType =>
      RouteType.custom(transitionsBuilder: customTransitionBuilder);

  @override
  List<AutoRoute> get routes => [];
}
