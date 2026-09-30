import 'package:auto_route/auto_route.dart';
import '../di/service_locator.dart';
import '../session/session_role.dart';
import 'app_router.gr.dart';
import 'role_guard.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  RouteType get defaultRouteType => const RouteType.adaptive();

  /// Le rôle est relu à chaque navigation, et non capturé à la construction
  /// du routeur : celui-ci naît avant la connexion, quand la session porte
  /// encore son repli `proprio`.
  final _ownerOnly = OwnerRouteGuard(() => sl<SessionRole>().value);

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: AuthRoute.page, initial: true),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: RegisterRoute.page),
    AutoRoute(page: TrialWelcomeRoute.page),
    // Ouverte à un compte inactif : c'est par elle qu'il redevient actif.
    AutoRoute(page: SubscriptionPlansRoute.page),
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: PropertyDetailRoute.page),
    AutoRoute(page: AllReviewsRoute.page),
    AutoRoute(page: PropertyRoute.page),
    AutoRoute(page: AddPropertyRoute.page, guards: [_ownerOnly]),
    AutoRoute(page: AddReservationRoute.page),
    AutoRoute(page: SuccessRoute.page),
    AutoRoute(page: ProfileRoute.page),
    AutoRoute(page: PropertyManagerProfileRoute.page, guards: [_ownerOnly]),
    AutoRoute(page: ResidenceRoute.page),
    AutoRoute(page: ResidenceDetailRoute.page),
    AutoRoute(page: AddResidenceRoute.page, guards: [_ownerOnly]),
    // Gestion des gérants : fermée au gérant lui-même, qui n'en ouvre pas.
    // `role_guard.dart` nommait déjà ces trois routes avant qu'elles existent.
    AutoRoute(page: GerantListRoute.page, guards: [_ownerOnly]),
    AutoRoute(page: AddGerantRoute.page, guards: [_ownerOnly]),
    AutoRoute(page: GerantScopeRoute.page, guards: [_ownerOnly]),
    AutoRoute(page: ExpenseRoute.page),
    AutoRoute(page: AddExpenseRoute.page),
    AutoRoute(page: ReservationRoute.page),
    AutoRoute(page: DetailsReservationRoute.page),
    AutoRoute(page: StayExtensionRoute.page),
    AutoRoute(page: EditReservationRoute.page),
    AutoRoute(page: FinanceRoute.page, guards: [_ownerOnly]),
    AutoRoute(page: ReportRoute.page, guards: [_ownerOnly]),
    AutoRoute(page: ClientsRoute.page),
    AutoRoute(page: AddClientRoute.page),
    AutoRoute(page: SupportChatRoute.page),
  ];
}
