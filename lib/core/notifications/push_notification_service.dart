import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  final _local = FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefresh;
  bool _started = false;

  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Canal Android des notifications, à importance haute : bannière et son.
  ///
  /// Déclaré aussi comme canal par défaut de FCM dans `AndroidManifest.xml`,
  /// et visé par le serveur (`RESI_ANDROID_CHANNEL`) : sans lui, Android
  /// rangeait les notifications dans le canal de secours de FCM, d'importance
  /// normale — une simple icône dans la barre d'état, que personne ne voyait.
  static const channelId = 'resi_default';

  /// Nom et description lus dans les réglages Android, donc dans la langue du
  /// téléphone. Choisie sur la locale de la plateforme et non par `tr()` : le
  /// canal se crée au démarrage, avant que les traductions soient chargées.
  /// Toute autre langue que l'anglais retombe sur le français, comme
  /// l'application elle-même.
  static AndroidNotificationChannel get _channel {
    final english = PlatformDispatcher.instance.locale.languageCode == 'en';
    return AndroidNotificationChannel(
      channelId,
      english ? 'RESI notifications' : 'Notifications RESI',
      description: english
          ? 'Subscription deadlines and messages from RESI.'
          : 'Échéances d’abonnement et messages de RESI.',
      importance: Importance.high,
    );
  }

  /// Branche les écouteurs, une fois, au démarrage de l'application.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      await _local.initialize(
        settings: const InitializationSettings(
          // Silhouette blanche sur fond transparent, comme l'exige la barre
          // d'état ; déclarée aussi pour FCM dans `AndroidManifest.xml`.
          android: AndroidInitializationSettings('@drawable/ic_notification'),
          iOS: DarwinInitializationSettings(
            // L'autorisation est demandée par FCM à la connexion, pas au
            // lancement : ne pas la redemander ici.
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) =>
            _openType(response.payload),
      );
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      // iOS affiche lui-même la bannière au premier plan quand on le lui
      // demande ; Android non, d'où [_showForeground].
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showForeground);

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

  /// Application ouverte : Android ne montre rien de lui-même. Une vraie
  /// notification système est posée — un toast de trois secondes, titre seul,
  /// passait inaperçu.
  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null || !Platform.isAndroid) return;

    try {
      await _local.show(
        id: message.messageId?.hashCode ?? notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            // Le corps entier, pas une ligne tronquée : une relance porte la
            // date d'échéance en fin de phrase.
            styleInformation: BigTextStyleInformation(notification.body ?? ''),
          ),
        ),
        payload: message.data['type'] as String?,
      );
    } catch (error) {
      // Repli : au moins le titre, plutôt que rien.
      final title = notification.title;
      if (title != null) AppToast.info(title);
      debugPrint('Notification locale non affichée : $error');
    }
  }

  void _open(RemoteMessage message) => _openType(message.data['type'] as String?);

  void _openType(String? type) {
    switch (PushDestination.fromData({'type': type})) {
      case PushDestination.subscription:
        _router.push(SubscriptionPlansRoute());
      case null:
        break;
    }
  }
}
