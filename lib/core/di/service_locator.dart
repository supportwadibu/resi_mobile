import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resi_africa/core/theme/theme_controller.dart';
import 'package:resi_africa/firebase_options.dart';
import 'package:resi_africa/features/auth/business_logic/auth_cubit.dart';
import 'package:resi_africa/features/auth/business_logic/owner_profile_cubit.dart';
import 'package:resi_africa/features/auth/data/repositories/auth_repository.dart';
import 'package:resi_africa/features/auth/data/repositories/owner_profile_repository.dart';
import 'package:resi_africa/features/auth/data/services/auth_service.dart';
import 'package:resi_africa/features/auth/data/services/google_auth_service.dart';
import 'package:resi_africa/features/auth/data/services/property_manager_service.dart';
import 'package:resi_africa/features/expense/business_logic/add_expense_cubit.dart';
import 'package:resi_africa/features/feedback/business_logic/feedback_cubit.dart';
import 'package:resi_africa/features/feedback/data/repositories/feedback_repository.dart';
import 'package:resi_africa/features/feedback/data/services/feedback_context_service.dart';
import 'package:resi_africa/features/rapport/business_logic/report_form_cubit.dart';
import 'package:resi_africa/features/rapport/data/repositories/rapport_repository.dart';
import 'package:resi_africa/features/expense/business_logic/expense_cubit.dart';
import 'package:resi_africa/features/expense/data/repositories/expense_repository.dart';
import 'package:resi_africa/features/reservation/business_logic/stay_extension_cubit.dart';
import 'package:resi_africa/features/reservation/business_logic/sync_review_cubit.dart';
import 'package:resi_africa/features/reservation/business_logic/edit_reservation_cubit.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';
import 'package:resi_africa/features/reservation/business_logic/early_check_out_cubit.dart';
import 'package:resi_africa/features/reservation/business_logic/stay_check_out_cubit.dart';
import 'package:resi_africa/features/home/business_logic/home_stats_cubit.dart';
import 'package:resi_africa/features/residence/business_logic/residence_cubit.dart';
import 'package:resi_africa/features/residence/business_logic/residence_detail_cubit.dart';
import 'package:resi_africa/features/residence/data/repositories/residence_repository.dart';
import 'package:resi_africa/features/property/business_logic/create_property_cubit.dart';
import 'package:resi_africa/features/property/business_logic/edit_property_cubit.dart';
import 'package:resi_africa/features/property/business_logic/property_cubit.dart';
import 'package:resi_africa/features/property/data/repositories/property_repository.dart';
import 'package:resi_africa/features/property/data/services/location_service.dart';
import 'package:resi_africa/features/clients/business_logic/add_client_cubit.dart';
import 'package:resi_africa/features/clients/business_logic/client_detail_cubit.dart';
import 'package:resi_africa/features/clients/business_logic/clients_cubit.dart';
import 'package:resi_africa/features/clients/data/repositories/clients_repository.dart';
import 'package:resi_africa/features/reservation/business_logic/add_reservation_cubit.dart';
import 'package:resi_africa/features/reservation/business_logic/add_reservation_state.dart';
import 'package:resi_africa/features/reservation/business_logic/reservation_cubit.dart';
import 'package:resi_africa/features/reservation/data/datasources/reservation_local_store.dart';
import 'package:resi_africa/features/reservation/data/repositories/reservation_repository.dart';
import 'package:resi_africa/features/gerant/business_logic/gerant_list_cubit.dart';
import 'package:resi_africa/features/gerant/business_logic/gerant_scope_cubit.dart';
import 'package:resi_africa/features/gerant/data/repositories/gerant_admin_repository.dart';
import 'package:resi_africa/features/gerant/data/repositories/gerant_repository.dart';
import 'package:resi_africa/features/stats/business_logic/dashboard_cubit.dart';
import 'package:resi_africa/features/stats/business_logic/finance_cubit.dart';
import 'package:resi_africa/features/stats/data/repositories/finance_repository.dart';
import 'package:resi_africa/features/stats/data/repositories/property_stats_repository.dart';
import 'package:resi_africa/features/subscription/business_logic/plan_cubit.dart';
import 'package:resi_africa/features/subscription/business_logic/subscription_plans_cubit.dart';
import 'package:resi_africa/features/subscription/data/repositories/subscription_repository.dart';

import '../api/api_client.dart';
import '../storage/app_database.dart';
import '../sync/pending_action_sender.dart';
import '../sync/sync_service.dart';
import '../api/interceptors/auth_interceptor.dart';
import '../api/interceptors/connectivity_interceptor.dart';
import '../api/interceptors/plan_interceptor.dart';
import '../api/plan_signals.dart';
import '../api/interceptors/retry_interceptor.dart';
import '../config/app_config.dart';
import '../notifications/device_token_repository.dart';
import '../notifications/push_notification_service.dart';
import '../offline/http_cache_store.dart';
import '../offline/offline_action_queue.dart';
import '../offline/offline_cache_interceptor.dart';
import '../offline/offline_prefetcher.dart';
import '../offline/offline_status.dart';
import '../offline/pending_action_store.dart';
import '../offline/pending_overlay.dart';
import '../offline/session_owner.dart';
import '../router/app_router.dart';
import '../session/session_role.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';

// ignore: non_constant_identifier_names
final sl = GetIt.instance;

Future<void> setupServiceLocator(AppConfig config) async {
  // ── Config ─────────────────────────────────────────────────────────────────
  sl.registerSingleton<AppConfig>(config);

  // ── Core ───────────────────────────────────────────────────────────────────
  sl.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  sl.registerSingleton<SecureStorage>(SecureStorage(sl()));
  sl.registerSingleton<Connectivity>(Connectivity());

  // ── Local Storage ─────────────────────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);
  sl.registerSingleton<LocalStorage>(LocalStorage(sl()));
  sl.registerSingleton<ThemeController>(ThemeController(sl()));

  // Enregistré avant les repositories : ils le reçoivent en dépendance, et le
  // rôle doit être connu avant le premier appel d'API.
  sl.registerSingleton<SessionRole>(SessionRole(sl<LocalStorage>()));

  sl.registerSingleton<GoogleSignIn>(
    GoogleSignIn(
      scopes: const ['email'],
      clientId:
          defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS
          ? DefaultFirebaseOptions.ios.iosClientId
          : null,
      serverClientId: AppConfig.googleServerClientId.isEmpty
          ? null
          : AppConfig.googleServerClientId,
    ),
  );
  sl.registerLazySingleton<GoogleAuthService>(() => GoogleAuthService(sl()));

  // Enregistrée avant l'intercepteur et `AuthService`, qui purgent tous deux
  // la base locale à la perte de session. Une seule instance : c'est celle
  // que `ReservationLocalStore` ouvre déjà.
  sl.registerSingleton<AppDatabase>(AppDatabase.instance);

  // ── Network ────────────────────────────────────────────────────────────────
  sl.registerSingleton<AuthInterceptor>(
    AuthInterceptor(sl<SecureStorage>(), sl<SessionRole>(), sl<AppDatabase>()),
  );
  sl.registerSingleton<RetryInterceptor>(RetryInterceptor());
  sl.registerSingleton<ConnectivityInterceptor>(ConnectivityInterceptor(sl()));
  sl.registerSingleton<PlanSignals>(PlanSignals());
  sl.registerSingleton<PlanInterceptor>(PlanInterceptor(sl()));

  // ── Hors ligne ─────────────────────────────────────────────────────────────
  // Singleton : le bandeau « hors ligne » et l'intercepteur partagent le même
  // signal.
  sl.registerSingleton<OfflineStatus>(OfflineStatus());
  sl.registerSingleton<HttpCacheStore>(HttpCacheStore(sl<AppDatabase>()));
  sl.registerSingleton<PendingActionStore>(
    PendingActionStore(sl<AppDatabase>()),
  );
  sl.registerSingleton<OfflineCacheInterceptor>(
    OfflineCacheInterceptor(
      store: sl<HttpCacheStore>(),
      status: sl<OfflineStatus>(),
      isOffline: () async {
        final results = await sl<Connectivity>().checkConnectivity();
        return results.every((r) => r == ConnectivityResult.none);
      },
      sessionOwner: () async =>
          jwtSubject(await sl<SecureStorage>().accessToken),
      // Résolu à l'appel : le store des réservations est déclaré plus bas.
      pendingSnapshot: () async => OverlaySnapshot(
        actions: await sl<PendingActionStore>().all(),
        pendingBookings: await sl<ReservationLocalStore>()
            .pendingBookingsAsJson(),
      ),
    ),
  );

  sl.registerSingleton<Dio>(
    buildDioClient(config, sl(), sl(), sl(), sl(), sl()),
  );

  // ── Router ─────────────────────────────────────────────────────────────────
  sl.registerSingleton<AppRouter>(AppRouter());

  // ── Features ───────────────────────────────────────────────────────────────
  // Repositories
  sl.registerLazySingleton(() => AuthRepository(sl<Dio>()));
  sl.registerLazySingleton(() => OwnerProfileRepository(sl<Dio>()));
  sl.registerLazySingleton(
    () => PropertyRepository(sl<Dio>(), sl<SessionRole>()),
  );
  sl.registerLazySingleton(
    () => ReservationRepository(sl<Dio>(), sl<SessionRole>()),
  );
  sl.registerLazySingleton(
    () => ClientsRepository(sl<Dio>(), sl<SessionRole>()),
  );
  sl.registerLazySingleton(() => ReservationLocalStore(sl<AppDatabase>()));
  sl.registerLazySingleton(
    () => ExpenseRepository(sl<Dio>(), sl<SessionRole>()),
  );
  sl.registerLazySingleton(
    () => ResidenceRepository(sl<Dio>(), sl<SessionRole>()),
  );
  sl.registerLazySingleton(
    () => FinanceRepository(sl<Dio>(), sl<SessionRole>()),
  );
  sl.registerLazySingleton(() => PropertyStatsRepository(sl<Dio>()));
  sl.registerLazySingleton(
    () => GerantRepository(sl<Dio>(), sl<SessionRole>()),
  );
  // Sans `SessionRole` : les routes `/proprio/managers` n'ont pas d'équivalent
  // sous le préfixe du gérant, qui ne gère pas de gérants.
  sl.registerLazySingleton(() => GerantAdminRepository(sl<Dio>()));
  sl.registerLazySingleton(() => FeedbackRepository(sl<Dio>()));
  sl.registerLazySingleton(() => RapportRepository(sl<Dio>()));

  // Services
  sl.registerLazySingleton(
    () => AuthService(
      sl<AuthRepository>(),
      sl<SecureStorage>(),
      sl<GoogleAuthService>(),
      sl<SessionRole>(),
      sl<AppDatabase>(),
      sl<LocalStorage>(),
      // Résolus à l'appel : le service push dépend lui-même d'`AuthService`.
      onSignedIn: () => sl<PushNotificationService>().registerDevice(),
      beforeSignOut: () => sl<PushNotificationService>().unregisterDevice(),
    ),
  );
  sl.registerLazySingleton(
    () => PushNotificationService(
      DeviceTokenRepository(sl<Dio>()),
      sl<AppRouter>(),
      isLoggedIn: () => sl<AuthService>().isLoggedIn(),
    ),
  );
  sl.registerLazySingleton<PropertyManagerService>(
    () => PropertyManagerService(
      sl<LocalStorage>(),
      sl<OwnerProfileRepository>(),
    ),
  );
  // Client HTTP propre : Nominatim ne doit pas recevoir le jeton Resi.
  sl.registerLazySingleton(() => LocationService());
  // Singleton : la version de l'application ne change pas en cours de session,
  // et le service la garde en cache après la première lecture.
  sl.registerLazySingleton(() => FeedbackContextService(sl<AppConfig>()));

  // Vide la file des réservations saisies hors réseau dès que la connexion
  // revient. Singleton : deux instances videraient la même file en parallèle
  // et enverraient deux fois la même réservation.
  sl.registerLazySingleton(
    () => SyncService(
      sl<ReservationLocalStore>(),
      sl<ReservationRepository>(),
      sl<ClientsRepository>(),
      sl<Connectivity>(),
      afterSync: () => sl<OfflinePrefetcher>().run(),
      actions: sl<PendingActionStore>(),
      sender: PendingActionSender(
        sl<ReservationRepository>(),
        sl<ClientsRepository>(),
        sl<ExpenseRepository>(),
      ),
    ),
  );

  // Les cubits d'action y déposent ce qu'ils ne peuvent envoyer ; le bandeau
  // de synchronisation compte aussitôt la saisie.
  sl.registerLazySingleton(
    () => OfflineActionQueue(
      sl<PendingActionStore>(),
      onQueued: () => sl<SyncService>().refreshCounters(),
    ),
  );

  // Singleton : deux passes concurrentes doubleraient la consommation de
  // données sans rien apporter.
  sl.registerLazySingleton(
    () => OfflinePrefetcher(
      isOnline: () async {
        final results = await sl<Connectivity>().checkConnectivity();
        return results.any((r) => r != ConnectivityResult.none);
      },
      // La synchronisation démarre au lancement, session ouverte ou non :
      // précharger sans jeton n'essuierait que des refus.
      isSignedIn: () => sl<AuthService>().isLoggedIn(),
    ),
  );

  // Cubits
  sl.registerFactory(
    () => AuthCubit(sl<AuthService>(), sl<PropertyManagerService>()),
  );
  sl.registerFactory(
    () => OwnerProfileCubit(
      sl<PropertyManagerService>(),
      sl<GerantRepository>(),
      // Lu à chaque chargement et non figé à l'enregistrement : le cubit est
      // une fabrique, mais le rôle change à la reconnexion sans que le
      // conteneur soit reconstruit.
      () => sl<SessionRole>().value,
    ),
  );
  sl.registerFactory(
    () => PropertyCubit(
      sl<PropertyRepository>(),
      sl<ReservationLocalStore>(),
      sl<ResidenceRepository>(),
    ),
  );
  sl.registerFactory(() => CreatePropertyCubit(sl<PropertyRepository>()));
  sl.registerFactory(() => EditPropertyCubit(sl<PropertyRepository>()));
  // Chaque liste dit ce qu'elle charge : aperçu de l'onglet, liste complète
  // paginée, ou réservations d'un bien. Sans paramètre, la liste complète.
  sl.registerFactoryParam<ReservationCubit, ReservationListOptions?, void>(
    (options, _) => ReservationCubit(
      sl<ReservationRepository>(),
      options: options ?? const ReservationListOptions(),
    ),
  );
  sl.registerFactory(
    () => StayExtensionCubit(
      sl<ReservationRepository>(),
      queue: sl<OfflineActionQueue>(),
    ),
  );
  // La réservation à modifier est passée à la création : le formulaire part
  // de ses valeurs, et le cubit ne la relit pas.
  sl.registerFactoryParam<EditReservationCubit, ReservationModel, void>(
    (reservation, _) =>
        EditReservationCubit(
          sl<ReservationRepository>(),
          reservation,
          queue: sl<OfflineActionQueue>(),
        ),
  );
  sl.registerFactory(
    () => StayCheckOutCubit(
      sl<ReservationRepository>(),
      queue: sl<OfflineActionQueue>(),
    ),
  );
  sl.registerFactory(
    () => EarlyCheckOutCubit(
      sl<ReservationRepository>(),
      queue: sl<OfflineActionQueue>(),
    ),
  );
  sl.registerFactory(
    () => ClientsCubit(sl<ClientsRepository>(), sl<ReservationLocalStore>()),
  );
  sl.registerFactory(
    () => ClientDetailCubit(
      sl<ClientsRepository>(),
      queue: sl<OfflineActionQueue>(),
    ),
  );
  sl.registerFactory(
    () => AddClientCubit(
      sl<ClientsRepository>(),
      queue: sl<OfflineActionQueue>(),
    ),
  );
  // Le mode est propre à chaque ouverture du formulaire : check-in immédiat ou
  // réservation future, choisi dans la boîte de dialogue d'entrée.
  sl.registerFactoryParam<AddReservationCubit, ReservationMode, void>(
    (mode, _) => AddReservationCubit(
      sl<ReservationRepository>(),
      sl<ClientsRepository>(),
      sl<ReservationLocalStore>(),
      sl<Connectivity>(),
      mode: mode,
    ),
  );
  sl.registerFactory(() => ExpenseCubit(sl<ExpenseRepository>()));
  sl.registerFactory(
    () => SyncReviewCubit(
      sl<ReservationLocalStore>(),
      sl<PendingActionStore>(),
      sl<SyncService>(),
    ),
  );
  sl.registerFactory(
    () => AddExpenseCubit(
      sl<ExpenseRepository>(),
      queue: sl<OfflineActionQueue>(),
    ),
  );
  sl.registerFactory(() => ResidenceCubit(sl<ResidenceRepository>()));
  sl.registerFactory(
    () => ResidenceDetailCubit(
      sl<ResidenceRepository>(),
      sl<PropertyRepository>(),
    ),
  );
  sl.registerFactory(() => GerantListCubit(sl<GerantAdminRepository>()));
  sl.registerFactory(
    () => GerantScopeCubit(
      sl<GerantAdminRepository>(),
      sl<ResidenceRepository>(),
      sl<PropertyRepository>(),
    ),
  );
  sl.registerFactory(() => FinanceCubit(sl<FinanceRepository>()));
  sl.registerFactory(
    () => HomeStatsCubit(
      sl<PropertyStatsRepository>(),
      sl<ReservationRepository>(),
      sl<FinanceRepository>(),
      sl<GerantRepository>(),
      // Lu à chaque chargement et non figé à l'enregistrement : le cubit est
      // une fabrique, mais le rôle change à la reconnexion sans que le
      // conteneur soit reconstruit.
      () => sl<SessionRole>().value,
    ),
  );
  sl.registerFactory(
    () => DashboardCubit(
      sl<FinanceRepository>(),
      sl<PropertyStatsRepository>(),
      sl<GerantRepository>(),
      // Lu à chaque chargement et non figé à l'enregistrement : le cubit est
      // une fabrique, mais le rôle change à la reconnexion sans que le
      // conteneur soit reconstruit.
      () => sl<SessionRole>().value,
    ),
  );
  sl.registerFactory(
    () => FeedbackCubit(sl<FeedbackRepository>(), sl<FeedbackContextService>()),
  );
  sl.registerFactory(
    () => ReportFormCubit(sl<RapportRepository>(), sl<ResidenceRepository>()),
  );

  // ── Abonnement ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => SubscriptionRepository(sl<Dio>()));
  // Singleton : les verrous posés dans toute l'application lisent le même
  // palier, et les refus de l'API doivent l'atteindre où qu'ils surviennent.
  sl.registerLazySingleton(
    () => PlanCubit(
      sl<AuthService>(),
      sl<LocalStorage>(),
      sl<SessionRole>(),
      sl<PlanSignals>(),
    ),
  );
  sl.registerFactory(
    () => SubscriptionPlansCubit(sl<SubscriptionRepository>(), sl<PlanCubit>()),
  );
}
