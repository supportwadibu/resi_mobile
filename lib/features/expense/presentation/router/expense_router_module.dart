import 'package:auto_route/auto_route.dart';
import 'package:resi_africa/core/custom_transition_builders.dart';
import 'expense_router_module.gr.dart';

// dart run build_runner build --delete-conflicting-outputs
@AutoRouterConfig(
  generateForDir: ['lib/features/expense/presentation/screens'],
  replaceInRouteName: 'Screen,Route',
)
class ExpenseRouterModule extends RootStackRouter {
  @override
  RouteType get defaultRouteType =>
      RouteType.custom(transitionsBuilder: customTransitionBuilder);

  @override
  List<AutoRoute> get routes => [AutoRoute(page: ExpenseRoute.page)];
}
