import 'package:auto_route/auto_route.dart';
import 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: AuthRoute.page, initial: true),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: RegisterRoute.page),
    AutoRoute(page: TrialWelcomeRoute.page),
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: PropertyDetailRoute.page),
    AutoRoute(page: AllReviewsRoute.page),
    AutoRoute(page: PropertyRoute.page),
    AutoRoute(page: AddPropertyRoute.page),
    AutoRoute(page: AddReservationRoute.page),
    AutoRoute(page: SuccessRoute.page),
    AutoRoute(page: ProfileRoute.page),
    AutoRoute(page: PropertyManagerProfileRoute.page),
    AutoRoute(page: ExpenseRoute.page),
    AutoRoute(page: AddExpenseRoute.page),
    AutoRoute(page: DetailsReservationRoute.page),
    AutoRoute(page: StayExtensionRoute.page),
    AutoRoute(page: FinanceRoute.page),
    AutoRoute(page: ReportRoute.page),
    AutoRoute(page: ClientsRoute.page),
    AutoRoute(page: AddClientRoute.page),
    AutoRoute(page: SupportChatRoute.page),
  ];
}
