import 'package:url_launcher/url_launcher.dart';

class LauncherHelper {
  LauncherHelper._();

  static Future<void> makeCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    await _launch(uri);
  }

  static Future<void> sendSms(String phoneNumber, {String? message}) async {
    final uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: message != null ? {'body': message} : null,
    );
    await _launch(uri);
  }

  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    await _launch(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> openNavigation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude'
      '${label != null ? '&destination_place_id=${Uri.encodeComponent(label)}' : ''}',
    );
    await _launch(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> openLocationOnMap({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final uri = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude'
      '${label != null ? '(${Uri.encodeComponent(label)})' : ''}',
    );

    if (await canLaunchUrl(uri)) {
      await _launch(uri);
    } else {
      await openNavigation(latitude: latitude, longitude: longitude, label: label);
    }
  }

  static Future<void> openWhatsApp(String phoneNumber, {String? message}) async {
    final encoded = message != null ? Uri.encodeComponent(message) : '';
    final uri = Uri.parse('https://wa.me/$phoneNumber${message != null ? '?text=$encoded' : ''}');
    await _launch(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> _launch(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    if (!await canLaunchUrl(uri)) {
      throw LauncherException('Impossible d\'ouvrir : $uri');
    }
    await launchUrl(uri, mode: mode);
  }
}

class LauncherException implements Exception {
  const LauncherException(this.message);
  final String message;

  @override
  String toString() => 'LauncherException: $message';
}