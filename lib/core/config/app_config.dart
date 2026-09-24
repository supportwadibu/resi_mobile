enum AppFlavor { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.baseUrl,
    required this.appName,
    this.enableLogging = false,
  });

  final AppFlavor flavor;
  final String baseUrl;
  final String appName;
  final bool enableLogging;

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '985472923092-22afjagqr55i117gtq2cl6hp0n2mma75.apps.googleusercontent.com',
  );

  static const String tawkPropertyId = String.fromEnvironment(
    'TAWK_PROPERTY_ID',
  );

  static const String tawkWidgetId = String.fromEnvironment(
    'TAWK_WIDGET_ID',
    defaultValue: 'default',
  );

  static bool get isSupportChatEnabled => tawkPropertyId.isNotEmpty;

  static String get tawkChatUrl =>
      'https://tawk.to/chat/$tawkPropertyId/$tawkWidgetId';

  static const String supportPhone = String.fromEnvironment(
    '2250757780335',
    defaultValue: '2250757780335',
  );

  static const String supportWhatsApp = String.fromEnvironment(
    '2250566511641',
    defaultValue: "2250566511641",
  );

  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@resi.africa',
  );

  static const String supportWebsite = String.fromEnvironment(
    'SUPPORT_WEBSITE',
    defaultValue: 'https://resi.africa',
  );

  static const String supportHours = String.fromEnvironment(
    'SUPPORT_HOURS',
    defaultValue: 'Lun – Sam, 8h – 20h',
  );

  bool get isProduction => flavor == AppFlavor.prod;
  bool get isDevelopment => flavor == AppFlavor.dev;

  static const String _devApiUrl = String.fromEnvironment(
    'DEV_API_URL',
    defaultValue: 'https://api-resi-africa.onrender.com',
  );

  static const dev = AppConfig(
    flavor: AppFlavor.dev,
    baseUrl: _devApiUrl,
    appName: 'App (Dev)',
    enableLogging: true,
  );

  /// Staging ne journalise pas : son `baseUrl` est celui de la production, et
  /// un build distribué à des testeurs imprimerait les jetons et les fiches
  /// clients réels dans une console lisible par quiconque tient l'appareil.
  static const staging = AppConfig(
    flavor: AppFlavor.staging,
    baseUrl: 'https://api-resi-africa.onrender.com',
    appName: 'App (Staging)',
  );

  static const prod = AppConfig(
    flavor: AppFlavor.prod,
    baseUrl: 'https://api-resi-africa.onrender.com',
    appName: 'App',
  );
}
