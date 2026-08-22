import 'package:dio/dio.dart';

class AppFailure implements Exception {
  const AppFailure._({
    required this.userMessage,
    this.debugMessage,
    this.statusCode,
  });
  final String userMessage;
  final String? debugMessage;

  /// Code HTTP à l'origine de l'échec, quand il y en a un.
  ///
  /// Certains appelants doivent distinguer une cause précise d'une autre — la
  /// synchronisation hors ligne traite un 409 (période déjà réservée) comme un
  /// conflit à arbitrer, non comme une panne à réessayer. Le lire ici plutôt
  /// que d'analyser `debugMessage`, dont le texte peut changer sans préavis.
  final int? statusCode;

  factory AppFailure.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return AppFailure.noInternet();

      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return AppFailure.timeout();

      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        final data = e.response?.data;

        if (code == 401) return AppFailure.unauthorized();
        if (code == 403) return AppFailure.forbidden();
        if (code == 404) return AppFailure.notFound();

        if (code == 422) {
          final errors =
              (data['errors'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, List<String>.from(v as List)),
              ) ??
              {};
          return AppFailure.validation(errors: errors);
        }

        return AppFailure.serverError(
          code: code,
          message: data?['message'] as String?,
        );

      default:
        return AppFailure.unexpected(message: e.message);
    }
  }

  factory AppFailure.noInternet() => const AppFailure._(userMessage: 'Pas de connexion internet.');
  factory AppFailure.timeout() => const AppFailure._(userMessage: 'La requete a expire. Reessayez.');
  factory AppFailure.unauthorized() => const AppFailure._(
        userMessage: 'Session expiree. Reconnectez-vous.',
        statusCode: 401,
      );
  factory AppFailure.forbidden() => const AppFailure._(
        userMessage: 'Acces refuse.',
        statusCode: 403,
      );
  factory AppFailure.notFound() => const AppFailure._(
        userMessage: 'Ressource introuvable.',
        statusCode: 404,
      );
  factory AppFailure.serverError({required int code, String? message}) => AppFailure._(
        // Un conflit n'est pas une panne : le serveur a compris la demande et
        // la refuse pour une raison métier, que l'appelant doit pouvoir
        // présenter telle quelle.
        userMessage: code == 409
            ? (message ?? 'Cette periode est deja reservee.')
            : 'Erreur serveur. Reessayez plus tard.',
        debugMessage: 'HTTP $code - $message',
        statusCode: code,
      );
  factory AppFailure.validation({required Map<String, List<String>> errors}) => AppFailure._(
        userMessage: errors.values.expand((e) => e).join('\n'),
      );
  factory AppFailure.unexpected({String? message}) => AppFailure._(
        userMessage: 'Une erreur inattendue est survenue.',
        debugMessage: message,
      );

  @override
  String toString() => 'AppFailure($userMessage | debug: $debugMessage)';
}
