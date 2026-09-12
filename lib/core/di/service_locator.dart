import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resi_africa/firebase_options.dart';
import 'package:resi_africa/features/auth/business_logic/auth_cubit.dart';
import 'package:resi_africa/features/auth/business_logic/owner_profile_cubit.dart';
import 'package:resi_africa/features/auth/data/repositories/auth_repository.dart';
import 'package:resi_africa/features/auth/data/repositories/owner_profile_repository.dart';
import 'package:resi_africa/features/auth/data/services/auth_service.dart';
import 'package:resi_africa/features/auth/data/services/google_auth_service.dart';
import 'package:resi_africa/features/auth/data/services/property_manager_service.dart';
import 'package:resi_africa/features/expense/business_logic/add_expense_cubit.dart';
import 'package:resi_africa/features/expense/business_logic/expense_cubit.dart';
import 'package:resi_africa/features/expense/data/repositories/expense_repository.dart';
import 'package:resi_africa/features/residence/business_logic/residence_cubit.dart';
import 'package:resi_africa/features/residence/data/repositories/residence_repository.dart';
import 'package:resi_africa/features/property/business_logic/create_property_cubit.dart';
import 'package:resi_africa/features/property/business_logic/property_cubit.dart';
import 'package:resi_africa/features/property/data/repositories/property_repository.dart';
import 'package:resi_africa/features/property/data/services/location_service.dart';
import 'package:resi_africa/features/clients/business_logic/clients_cubit.dart';
import 'package:resi_africa/features/clients/data/repositories/clients_repository.dart';
import 'package:resi_africa/features/reservation/business_logic/add_reservation_cubit.dart';
import 'package:resi_africa/features/reservation/business_logic/add_reservation_state.dart';
import 'package:resi_africa/features/reservation/business_logic/reservation_cubit.dart';
import 'package:resi_africa/features/reservation/data/datasources/reservation_local_store.dart';
import 'package:resi_africa/features/reservation/data/repositories/reservation_repository.dart';
import 'package:resi_africa/features/stats/business_logic/finance_cubit.dart';
import 'package:resi_africa/features/stats/data/repositories/finance_repository.dart';

import '../api/api_client.dart';
import '../storage/app_database.dart';
import '../sync/sync_service.dart';
import '../api/interceptors/auth_interceptor.dart';
import '../api/interceptors/connectivity_interceptor.dart';
import '../api/interceptors/retry_interceptor.dart';
import '../config/app_config.dart';
import '../router/app_router.dart';
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

  sl.registerSingleton<GoogleSignIn>(
    GoogleSignIn(
      scopes: const ['email'],
      clientId: defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS
          ? DefaultFirebaseOptions.ios.iosClientId
          : null,
      serverClientId: AppConfig.googleServerClientId.isEmpty
          ? null
          : AppConfig.googleServerClientId,
    ),
  );
  sl.registerLazySingleton<GoogleAuthService>(
    () => GoogleAuthService(sl()),
  );

  // ── Network ────────────────────────────────────────────────────────────────
  sl.registerSingleton<AuthInterceptor>(AuthInterceptor(sl()));
  sl.registerSingleton<RetryInterceptor>(RetryInterceptor());
  sl.registerSingleton<ConnectivityInterceptor>(ConnectivityInterceptor(sl()));
  sl.registerSingleton<Dio>(buildDioClient(config, sl(), sl(), sl()));

  // ── Router ─────────────────────────────────────────────────────────────────
  sl.registerSingleton<AppRouter>(AppRouter());

  // ── Features ───────────────────────────────────────────────────────────────
// Repositories
  sl.registerLazySingleton(() => AuthRepository(sl<Dio>()));
  sl.registerLazySingleton(() => OwnerProfileRepository(sl<Dio>()));
  sl.registerLazySingleton(() => PropertyRepository(sl<Dio>()));
  sl.registerLazySingleton(() => ReservationRepository(sl<Dio>()));
  sl.registerLazySingleton(() => ClientsRepository(sl<Dio>()));
  sl.registerLazySingleton(
    () => ReservationLocalStore(AppDatabase.instance),
  );
  sl.registerLazySingleton(() => ExpenseRepository(sl<Dio>()));
  sl.registerLazySingleton(() => ResidenceRepository(sl<Dio>()));
  sl.registerLazySingleton(() => FinanceRepository(sl<Dio>()));

  // Services
  sl.registerLazySingleton(
    () => AuthService(
      sl<AuthRepository>(),
      sl<SecureStorage>(),
      sl<GoogleAuthService>(),
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

  // Vide la file des réservations saisies hors réseau dès que la connexion
  // revient. Singleton : deux instances videraient la même file en parallèle
  // et enverraient deux fois la même réservation.
  sl.registerLazySingleton(
    () => SyncService(
      sl<ReservationLocalStore>(),
      sl<ReservationRepository>(),
      sl<ClientsRepository>(),
      sl<Connectivity>(),
    ),
  );

  // Cubits
  sl.registerFactory(
    () => AuthCubit(sl<AuthService>(), sl<PropertyManagerService>()),
  );
  sl.registerFactory(
    () => OwnerProfileCubit(sl<PropertyManagerService>()),
  );
  sl.registerFactory(
    () => PropertyCubit(
      sl<PropertyRepository>(),
      sl<ReservationLocalStore>(),
      sl<ResidenceRepository>(),
    ),
  );
  sl.registerFactory(() => CreatePropertyCubit(sl<PropertyRepository>()));
  sl.registerFactory(() => ReservationCubit(sl<ReservationRepository>()));
  sl.registerFactory(
    () => ClientsCubit(sl<ClientsRepository>(), sl<ReservationLocalStore>()),
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
  sl.registerFactory(() => AddExpenseCubit(sl<ExpenseRepository>()));
  sl.registerFactory(() => ResidenceCubit(sl<ResidenceRepository>()));
  sl.registerFactory(() => FinanceCubit(sl<FinanceRepository>()));
}
