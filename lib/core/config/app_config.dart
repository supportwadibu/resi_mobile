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

  /// Identifiants du widget de chat Tawk.to.
  ///
  /// Relevés dans le tableau de bord Tawk.to, sous *Administration >
  /// Chat Widget* : l'URL directe s'y lit
  /// `https://tawk.to/chat/<propertyId>/<widgetId>`.
  ///
  /// Ce ne sont pas des secrets — ils voyagent dans la page publique du
  /// widget — mais ils restent surchargeables au build pour distinguer un
  /// canal de test d'un canal de production.
  static const String tawkPropertyId = String.fromEnvironment(
    'TAWK_PROPERTY_ID',
  );

  static const String tawkWidgetId = String.fromEnvironment(
    'TAWK_WIDGET_ID',
    defaultValue: 'default',
  );

  /// Le support n'est proposé que si le widget est réellement configuré :
  /// une page de chat vide vaut moins qu'une entrée absente.
  static bool get isSupportChatEnabled => tawkPropertyId.isNotEmpty;

  static String get tawkChatUrl =>
      'https://tawk.to/chat/$tawkPropertyId/$tawkWidgetId';

  bool get isProduction => flavor == AppFlavor.prod;
  bool get isDevelopment => flavor == AppFlavor.dev;

  static const String _devApiUrl = String.fromEnvironment(
    'DEV_API_URL',
    defaultValue: 'https://resi-api.onrender.com',
  );

  static const dev = AppConfig(
    flavor: AppFlavor.dev,
    baseUrl: _devApiUrl,
    appName: 'App (Dev)',
    enableLogging: true,
  );

  static const staging = AppConfig(
    flavor: AppFlavor.staging,
    baseUrl: 'https://resi-api.onrender.com',
    appName: 'App (Staging)',
    enableLogging: true,
  );

  static const prod = AppConfig(
    flavor: AppFlavor.prod,
    baseUrl: 'https://resi-api.onrender.com',
    appName: 'App',
  );
}
