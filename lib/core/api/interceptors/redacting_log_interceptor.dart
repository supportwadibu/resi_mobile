import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';


class RedactingLogInterceptor extends Interceptor {
  const RedactingLogInterceptor();

  static const _sensitiveHeaders = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
  };

  static const _sensitiveFields = {
    'password',
    'password_confirmation',
    'old_password',
    'new_password',
    'access_token',
    'refresh_token',
    'token',
    'otp',
    'otp_code',
    'dev_otp_code',
    'verification_code',
    'secret',
    'id_token',
    'client_secret',
  };

  static const _redacted = '***';

  /// Longueur au-delà de laquelle un corps est résumé plutôt qu'imprimé.
  ///
  /// Une liste de biens avec ses images tient sur des centaines de lignes et
  /// noierait la console sans rien apprendre.
  static const _maxBodyLength = 2000;

  bool get _enabled => kDebugMode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_enabled) {
      debugPrint('→ ${options.method} ${options.uri}');
      debugPrint('  headers: ${_redactHeaders(options.headers)}');

      if (options.data != null) {
        debugPrint('  body: ${_redactBody(options.data)}');
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_enabled) {
      debugPrint(
        '← ${response.statusCode} ${response.requestOptions.method} '
        '${response.requestOptions.uri}',
      );
      if (response.data != null) {
        debugPrint('  body: ${_redactBody(response.data)}');
      }
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_enabled) {
      debugPrint(
        '✗ ${err.response?.statusCode ?? err.type.name} '
        '${err.requestOptions.method} ${err.requestOptions.uri}',
      );
      if (err.response?.data != null) {
        debugPrint('  body: ${_redactBody(err.response!.data)}');
      }
    }

    handler.next(err);
  }

  Map<String, dynamic> _redactHeaders(Map<String, dynamic> headers) {
    return {
      for (final entry in headers.entries)
        entry.key: _sensitiveHeaders.contains(entry.key.toLowerCase())
            ? _redacted
            : entry.value,
    };
  }

  /// Rend le corps lisible, valeurs sensibles masquées.
  ///
  /// `FormData` n'est jamais imprimé : un dépôt de pièce d'identité y transporte
  /// le fichier entier, et son contenu n'a rien à faire dans un journal.
  String _redactBody(Object? data) {
    if (data is FormData) {
      final fields = data.fields.map((f) => f.key).join(', ');
      return 'FormData(champs: [$fields], fichiers: ${data.files.length})';
    }

    final redacted = _redactValue(data);

    String rendered;
    try {
      rendered = jsonEncode(redacted);
    } catch (_) {
      // Un corps non sérialisable (flux, binaire) n'a pas de représentation
      // utile : son type suffit à situer l'appel.
      return '<${data.runtimeType}>';
    }

    return rendered.length > _maxBodyLength
        ? '${rendered.substring(0, _maxBodyLength)}… (tronqué)'
        : rendered;
  }

  /// Parcourt récursivement la structure : un jeton imbriqué dans `data` doit
  /// être masqué comme s'il était à la racine.
  Object? _redactValue(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key: _sensitiveFields.contains(
                entry.key.toString().toLowerCase(),
              )
              ? _redacted
              : _redactValue(entry.value),
      };
    }

    if (value is List) return value.map(_redactValue).toList();

    return value;
  }
}
