import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/config/app_config.dart';
import '../models/feedback_model.dart';

/// Assemble le contexte technique joint à chaque avis.
///
/// Aucune de ces informations n'est demandée à l'utilisateur : il décrit un
/// problème dans ses mots, et c'est à l'application de dire sur quelle version
/// et quel appareil il l'a rencontré.
///
/// Le modèle exact d'appareil demanderait `device_info_plus`, un paquet de plus
/// pour une donnée que `Platform.operatingSystemVersion` porte déjà en partie
/// sur Android ; on s'en tient donc à ce que la bibliothèque standard expose.
class FeedbackContextService {
  FeedbackContextService(this._config);

  final AppConfig _config;

  /// Version de l'application, lue une seule fois.
  ///
  /// `PackageInfo.fromPlatform` traverse le canal de plateforme : la relire à
  /// chaque ouverture du formulaire ajouterait une latence inutile.
  String? _cachedVersion;

  Future<FeedbackContext> collect() async {
    return FeedbackContext(
      appVersion: await _appVersion(),
      flavor: _config.flavor.name,
      platform: _platform(),
      osVersion: _osVersion(),
      deviceModel: _deviceModel(),
    );
  }

  Future<String?> _appVersion() async {
    if (_cachedVersion != null) return _cachedVersion;

    try {
      final info = await PackageInfo.fromPlatform();
      _cachedVersion = '${info.version}+${info.buildNumber}';
      return _cachedVersion;
    } catch (_) {
      // Un contexte incomplet vaut mieux qu'un avis perdu : l'API accepte
      // chacun de ces champs absent.
      return null;
    }
  }

  String? _platform() {
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return null;
    }
  }

  String? _osVersion() {
    try {
      return Platform.operatingSystemVersion;
    } catch (_) {
      return null;
    }
  }

  /// Nom réseau de l'appareil, quand le système le donne.
  ///
  /// Ce n'est pas le modèle commercial, mais c'est la seule identification
  /// d'appareil accessible sans dépendance supplémentaire — et elle suffit
  /// souvent à distinguer deux signalements du même utilisateur.
  String? _deviceModel() {
    try {
      final name = Platform.localHostname;
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }
}
