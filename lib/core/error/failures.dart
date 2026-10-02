import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';

/// Extrait le code metier stable du corps d'une reponse d'erreur.
///
/// Le corps n'est pas toujours l'objet attendu : un proxy en panne renvoie de
/// l'HTML, et un champ `code` numerique existe ailleurs dans l'API. Tout ce
/// qui n'est pas une chaine non vide vaut absence — faire lever ici priverait
/// la synchronisation de son refus et lui ferait perdre la saisie.
String? parseErrorCode(dynamic data) {
  if (data is! Map) return null;
  final code = data['code'];
  if (code is! String) return null;
  final trimmed = code.trim();
  return trimmed.isEmpty ? null : trimmed;
}

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

/// L'application est-elle affichée en français ?
///
/// Lu sur `Intl.defaultLocale`, que l'application aligne sur la langue
/// active : une `AppFailure` naît dans un repository, sans `BuildContext`.
bool get _isFrench => Intl.getCurrentLocale().startsWith('fr');

/// Message d'un refus métier de l'API, dans la langue de l'application.
///
/// L'API rédige ses messages en français. Sur un téléphone en français, le
/// sien fait foi : il porte des précisions (un nombre de jours, un reste dû)
/// qu'une traduction par code perdrait. Dans une autre langue, le texte
/// français est écarté au profit de la traduction du code ; un code inconnu
/// rend `null`, et l'appelant retombe sur son libellé générique plutôt que
/// d'afficher du français.
String? localizedServerMessage(String? code, String? serverMessage) {
  final message = serverMessage?.trim();
  if (_isFrench && message != null && message.isNotEmpty) return message;
  final key = 'api_errors.$code';
  if (code != null && key.trExists()) return key.tr();
  return null;
}

class AppFailure implements Exception {
  const AppFailure._({
    required this.userMessage,
    this.debugMessage,
    this.statusCode,
    this.code,
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

  /// Code métier stable renvoyé par l'API, quand elle en fournit un.
  ///
  /// Distinct du `statusCode` HTTP : deux refus partagent le même 403 sans
  /// appeler la même réaction — un logement sorti du périmètre est définitif,
  /// un jeton expiré ne l'est pas. Le texte du message ne peut pas servir à
  /// trancher : il est destiné à l'utilisateur et peut être reformulé.
  final String? code;

  /// Compte inactif : aucun abonnement en cours, il faut souscrire un forfait.
  bool get isSubscriptionRequired => code == 'subscription_required';

  /// Fonction réservée au forfait 5 000 F, refusée au forfait 3 000 F.
  bool get isPlanUpgradeRequired => code == 'plan_upgrade_required';

  factory AppFailure.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return AppFailure.noInternet();

      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return AppFailure.timeout();

      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        final data = e.response?.data;

        // Lu pour tous les statuts, pas seulement le 403 : d'autres refus
        // portent un code métier que l'appelant doit pouvoir distinguer.
        final businessCode = parseErrorCode(data);

        if (status == 401) return AppFailure.unauthorized();
        if (status == 403) {
          return AppFailure.forbidden(
            message: data is Map ? data['message'] as String? : null,
            code: businessCode,
          );
        }
        if (status == 404) return AppFailure.notFound(code: businessCode);

        if (status == 422) {
          return AppFailure.validation(
            errors: parseValidationErrors(data),
            code: businessCode,
          );
        }

        return AppFailure.serverError(
          code: status,
          // Le corps peut n'être pas un objet — un proxy en panne renvoie de
          // l'HTML : le lire sans vérifier lèverait au lieu de rendre un refus.
          message: data is Map ? data['message'] as String? : null,
          businessCode: businessCode,
        );

      default:
        return AppFailure.unexpected(message: e.message);
    }
  }

  factory AppFailure.noInternet() =>
      AppFailure._(userMessage: 'errors.no_internet'.tr());
  factory AppFailure.timeout() =>
      AppFailure._(userMessage: 'errors.timeout'.tr());

  /// Hors réseau, et rien en cache pour cette lecture : l'écran n'a jamais
  /// été ouvert en ligne. Distincte de [AppFailure.noInternet] pour dire
  /// pourquoi le reste de l'application, lui, s'affiche.
  factory AppFailure.offlineUnavailable() => AppFailure._(
    userMessage: 'errors.offline_unavailable'.tr(),
    code: offlineUnavailableCode,
  );

  /// Code de [AppFailure.offlineUnavailable], lu par les repositories qui
  /// savent recomposer une lecture à partir d'une autre déjà en cache.
  static const offlineUnavailableCode = 'offline_unavailable';

  /// Lecture impossible faute de réseau et de cache.
  bool get isOfflineUnavailable => code == offlineUnavailableCode;
  factory AppFailure.unauthorized() => AppFailure._(
    userMessage: 'errors.session_expired'.tr(),
    statusCode: 401,
  );

  /// [message] : explication renvoyée par l'API, préférée au libellé générique.
  ///
  /// Un 403 métier dit souvent quoi faire pour lever le refus — « Complétez
  /// votre dossier avant de publier une annonce ». L'écraser par « Accès
  /// refusé » laisserait le propriétaire devant une impasse sans issue.
  ///
  /// Ce report du message est un **changement assumé** : auparavant tout 403
  /// affichait le seul libellé générique. Il vaut pour toute l'application,
  /// pas pour le seul gérant. Revenir au générique se verrait — des tests le
  /// verrouillent dans `failures_code_test.dart`.
  factory AppFailure.forbidden({String? message, String? code}) => AppFailure._(
    userMessage:
        localizedServerMessage(code, message) ?? 'errors.forbidden'.tr(),
    statusCode: 403,
    code: code,
  );
  factory AppFailure.notFound({String? code}) => AppFailure._(
    userMessage: 'errors.not_found'.tr(),
    statusCode: 404,
    code: code,
  );

  /// [code] : statut HTTP. [businessCode] : code métier du corps de réponse.
  ///
  /// Les deux noms se ressemblent pour une raison historique — `code` désignait
  /// le statut avant que l'API n'expose un code métier — et les renommer
  /// casserait les appels existants.
  factory AppFailure.serverError({
    required int code,
    String? message,
    String? businessCode,
  }) => AppFailure._(
    // Un conflit n'est pas une panne : le serveur a compris la demande et
    // la refuse pour une raison métier, que l'appelant doit pouvoir
    // présenter telle quelle.
    userMessage: code == 409
        ? localizedServerMessage(businessCode, message) ??
              'errors.period_taken'.tr()
        : 'errors.server'.tr(),
    debugMessage: 'HTTP $code - $message',
    statusCode: code,
    code: businessCode,
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
    String? code,
  }) => AppFailure._(
    // Les erreurs de champ viennent de VineJS, qui les rédige en anglais :
    // elles ne s'affichent que là où elles sont dans la langue de l'écran.
    // Ailleurs — et quand le serveur renvoie une forme non reconnue —, un
    // message générique vaut mieux qu'une bulle vide ou dans une autre langue.
    userMessage: errors.isNotEmpty && !_isFrench
        ? errors.values.expand((e) => e).join('\n')
        : localizedServerMessage(code, null) ??
              'errors.validation_rejected'.tr(),
    debugMessage: 'HTTP $statusCode - $errors',
    statusCode: statusCode,
    code: code,
  );
  /// Refus dont le message est déjà rédigé dans la langue de l'application.
  ///
  /// Distinct de [AppFailure.validation], qui écarte en français les erreurs
  /// de champ venues de VineJS : un message que l'application a traduit
  /// elle-même doit, lui, toujours s'afficher.
  factory AppFailure.localized({
    required String message,
    int? statusCode,
    String? code,
  }) => AppFailure._(
    userMessage: message,
    debugMessage: 'HTTP $statusCode - $code',
    statusCode: statusCode,
    code: code,
  );
  factory AppFailure.unexpected({String? message}) => AppFailure._(
    userMessage: 'errors.unexpected'.tr(),
    debugMessage: message,
  );

  @override
  String toString() => 'AppFailure($userMessage | debug: $debugMessage)';
}
