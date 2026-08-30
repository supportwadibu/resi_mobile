import 'package:dio/dio.dart';

/// Extrait les erreurs de validation d'une reponse 422.
///
/// Deux formes coexistent et doivent etre lues indifferemment : VineJS renvoie
/// une **liste** d'objets `{field, message, rule}`, tandis que d'autres points
/// d'entree renvoient une **map** `champ -> [messages]`. N'en lire qu'une
/// laissait le message vide, et le refus s'affichait sans rien expliquer.
Map<String, List<String>> parseValidationErrors(dynamic data) {
  if (data is! Map) return const {};
  final errors = data['errors'];

  if (errors is List) {
    final parsed = <String, List<String>>{};
    for (final entry in errors) {
      if (entry is! Map) continue;
      final field = entry['field']?.toString() ?? '_';
      final message = entry['message']?.toString();
      if (message == null) continue;
      parsed.putIfAbsent(field, () => <String>[]).add(message);
    }
    return parsed;
  }

  if (errors is Map) {
    return errors.map(
      (key, value) => MapEntry(
        key.toString(),
        value is List
            ? value.map((e) => e.toString()).toList()
            : <String>[value.toString()],
      ),
    );
  }

  return const {};
}

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
          return AppFailure.validation(errors: parseValidationErrors(data));
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
  /// Refus de validation du serveur.
  ///
  /// `statusCode` est indispensable : sans lui, l'appelant ne distingue pas ce
  /// refus d'une panne de transport. La creation de reservation lisait alors
  /// un 422 comme une coupure reseau, mettait la saisie en file et affichait
  /// un ecran de succes — l'argent etait encaisse, la reservation n'existait
  /// nulle part, et chaque synchronisation rejouait le meme refus.
  factory AppFailure.validation({
    required Map<String, List<String>> errors,
    int statusCode = 422,
  }) => AppFailure._(
        userMessage: errors.isEmpty
            // Le serveur peut renvoyer ses erreurs sous une forme non reconnue :
            // mieux vaut un message generique qu'une bulle vide.
            ? 'Les informations saisies ont ete refusees par le serveur.'
            : errors.values.expand((e) => e).join('\n'),
        debugMessage: 'HTTP $statusCode - $errors',
        statusCode: statusCode,
      );
  factory AppFailure.unexpected({String? message}) => AppFailure._(
        userMessage: 'Une erreur inattendue est survenue.',
        debugMessage: message,
      );

  @override
  String toString() => 'AppFailure($userMessage | debug: $debugMessage)';
}
