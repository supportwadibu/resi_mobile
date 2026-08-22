import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../app.dart';
import '../firebase_options.dart';
import 'bloc/app_bloc_observer.dart';
import 'config/app_config.dart';
import 'di/service_locator.dart';
import 'sync/sync_service.dart';

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await EasyLocalization.ensureInitialized();

  // Sans ces données, tout `DateFormat(..., 'fr')` lève une `LocaleDataException`
  // à la première mise en forme d'une date.
  await initializeDateFormatting('fr');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Bloc.observer = AppBlocObserver(enableLogging: config.enableLogging);

  await setupServiceLocator(config);

  // Écoute le réseau et vide la file des réservations saisies hors ligne.
  // Lancé sans attendre : une file vide ne doit pas retarder l'affichage, et
  // un envoi en cours se poursuit pendant que l'application démarre.
  unawaited(sl<SyncService>().start());

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('fr'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      child: App(config: config),
    ),
  );
}
