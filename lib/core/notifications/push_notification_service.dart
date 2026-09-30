import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../shared/widgets/app_toast.dart';
import '../router/app_router.dart';
import '../router/app_router.gr.dart';
import 'device_token_repository.dart';
import 'push_destination.dart';

/// Notifications push de l'appareil : autorisation, jeton, affichage et
/// ouverture.
///
/// Le jeton est déclaré au serveur à chaque ouverture de session et à chaque
/// renouvellement par FCM, et retiré à la déconnexion : l'appareil ne doit
/// recevoir que les notifications du compte connecté.
///
/// Toute erreur est avalée : une notification est un confort, et son échec ne
/// doit jamais empêcher la connexion ni la déconnexion.
class PushNotificationService {
  PushNotificationService(
    this._repository,
    this._router, {
    required Future<bool> Function() isLoggedIn,
  }) : _isLoggedIn = isLoggedIn;

  final DeviceTokenRepository _repository;
  final AppRouter _router;
  final Future<bool> Function() _isLoggedIn;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  StreamSubscription<String>? _tokenRefresh;
  bool _started = false;

  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Branche les écouteurs, une fois, au démarrage de l'application.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      // Au premier plan, Android n'affiche pas la notification lui-même : un
      // toast la montre, sans quoi elle passerait inaperçue.
      FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title;
        if (title != null) AppToast.info(title);
      });

      FirebaseMessaging.onMessageOpenedApp.listen(_open);

      // Application tuée puis ouverte par le toucher d'une notification.
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _open(initial);

      if (await _isLoggedIn()) await registerDevice();
    } catch (error) {
      debugPrint('Notifications push indisponibles : $error');
    }
  }

  /// Déclare l'appareil pour le compte connecté.
  ///
  /// Demande l'autorisation au besoin : Android 13+ et iOS l'exigent, et un
  /// refus laisse simplement l'appareil sans notification.
  Future<void> registerDevice() async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _messaging.getToken();
      if (token != null) {
        await _repository.register(token, platform: _platform);
      }

      await _tokenRefresh?.cancel();
      _tokenRefresh = _messaging.onTokenRefresh.listen((fresh) async {
        try {
          await _repository.register(fresh, platform: _platform);
        } catch (_) {
          // Réessayé à la prochaine ouverture de session.
        }
      });
    } catch (error) {
      debugPrint('Appareil non déclaré pour les notifications : $error');
    }
  }

  /// Retire l'appareil du compte — **avant** l'effacement des jetons de
  /// session, faute de quoi le serveur refuserait l'appel.
  Future<void> unregisterDevice() async {
    try {
      await _tokenRefresh?.cancel();
      _tokenRefresh = null;

      final token = await _messaging.getToken();
      if (token != null) await _repository.unregister(token);
    } catch (error) {
      debugPrint('Appareil non retiré des notifications : $error');
    }
  }

  void _open(RemoteMessage message) {
    switch (PushDestination.fromData(message.data)) {
      case PushDestination.subscription:
        _router.push(SubscriptionPlansRoute());
      case null:
        break;
    }
  }
}
