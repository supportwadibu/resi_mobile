import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/error/exception_mapper.dart';
import 'package:resi_africa/core/error/failures.dart';
import 'package:resi_africa/core/offline/cache_keys.dart';
import 'package:resi_africa/core/offline/http_cache_store.dart';
import 'package:resi_africa/core/offline/offline_cache_interceptor.dart';
import 'package:resi_africa/core/offline/offline_status.dart';
import 'package:resi_africa/core/offline/session_owner.dart';

import '../../support/spy_database.dart';
import '../../support/translations_fixture.dart';

/// Cache en mémoire : le comportement testé est celui de l'intercepteur, pas
/// de SQLite.
class _MemoryCacheStore extends HttpCacheStore {
  _MemoryCacheStore() : super(SpyDatabase());

  final rows = <String, CachedBody>{};

  @override
  Future<CachedBody?> read(CacheKeys keys) async =>
      rows[keys.exact] ?? (keys.loose == null ? null : rows[keys.loose]);

  @override
  Future<void> write(
    CacheKeys keys, {
    required String path,
    required String body,
    DateTime? at,
  }) async {
    final row = CachedBody(body: body, cachedAt: at ?? DateTime.now());
    rows[keys.exact] = row;
    if (keys.loose != null) rows[keys.loose!] = row;
  }
}

/// Serveur simulé : répond, échoue en transport, ou renvoie un statut.
class _FakeAdapter implements HttpClientAdapter {
  Object? Function(RequestOptions options)? respond;
  int? status;
  bool failTransport = false;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (failTransport) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'réseau injoignable',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(respond?.call(options) ?? const {'data': []}),
      status ?? 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(loadTestTranslations);

  late _MemoryCacheStore store;
  late OfflineStatus status;
  late _FakeAdapter adapter;
  late bool offline;
  late Dio dio;

  setUp(() {
    store = _MemoryCacheStore();
    status = OfflineStatus();
    adapter = _FakeAdapter();
    offline = false;
    dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        OfflineCacheInterceptor(
          store: store,
          status: status,
          isOffline: () async => offline,
          sessionOwner: () async => 'owner-1',
        ),
      );
  });

  test('une lecture réussie est gardée et sert hors ligne', () async {
    adapter.respond = (_) => {
      'data': [
        {'id': 'b1'},
      ],
    };
    await dio.get<dynamic>('/proprio/bookings', queryParameters: {'page': 1});

    offline = true;
    final cached = await dio.get<dynamic>(
      '/proprio/bookings',
      queryParameters: {'page': 1},
    );

    expect(adapter.calls, 1, reason: 'hors ligne, aucune tentative réseau');
    expect((cached.data as Map)['data'], [
      {'id': 'b1'},
    ]);
    expect(cached.extra[offlineCachedAtExtra], isA<DateTime>());
    expect(status.value, isNotNull);
  });

  test('un échec de transport se rabat sur le cache — Wi-Fi sans Internet',
      () async {
    await dio.get<dynamic>('/proprio/properties');

    adapter.failTransport = true;
    final cached = await dio.get<dynamic>('/proprio/properties');

    expect(cached.statusCode, 200);
    expect(cached.extra[offlineCachedAtExtra], isNotNull);
  });

  test('un 5xx se rabat sur le cache', () async {
    await dio.get<dynamic>('/proprio/clients');

    adapter.status = 503;
    final cached = await dio.get<dynamic>('/proprio/clients');

    expect(cached.extra[offlineCachedAtExtra], isNotNull);
  });

  test('un 4xx n’est jamais masqué par le cache', () async {
    await dio.get<dynamic>('/proprio/clients');

    adapter.status = 403;
    await expectLater(
      dio.get<dynamic>('/proprio/clients'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statut',
          403,
        ),
      ),
    );
  });

  test('sans cache, l’échec dit que l’écran n’est pas disponible hors ligne',
      () async {
    offline = true;

    try {
      await dio.get<dynamic>('/proprio/expenses');
      fail('la lecture aurait dû échouer');
    } on DioException catch (e) {
      final failure = mapDioExceptionToFailure(e);
      expect(failure.isOfflineUnavailable, isTrue);
    }
  });

  test('une lecture hors cache n’est jamais servie depuis le cache', () async {
    await dio.get<dynamic>('/proprio/subscription');

    offline = true;
    // L'intercepteur laisse passer : l'échec vient du transport simulé.
    adapter.failTransport = true;
    await expectLater(
      dio.get<dynamic>('/proprio/subscription'),
      throwsA(isA<DioException>()),
    );
  });

  test('une écriture ne passe jamais par le cache', () async {
    offline = true;
    adapter.failTransport = true;

    await expectLater(
      dio.post<dynamic>('/proprio/expenses', data: const {}),
      throwsA(
        isA<DioException>().having(
          (e) => e.error is AppFailure &&
              (e.error! as AppFailure).isOfflineUnavailable,
          'hors cache',
          isFalse,
        ),
      ),
    );
  });

  test('une lecture réussie efface le signal hors ligne', () async {
    await dio.get<dynamic>('/proprio/bookings');
    offline = true;
    await dio.get<dynamic>('/proprio/bookings');
    expect(status.value, isNotNull);

    offline = false;
    await dio.get<dynamic>('/proprio/bookings');

    expect(status.value, isNull);
  });

  test('la lecture en ligne n’est pas rejouée par RetryInterceptor', () async {
    late RequestOptions seen;
    adapter.respond = (options) {
      seen = options;
      return const {'data': []};
    };

    await dio.get<dynamic>('/proprio/bookings');

    expect(seen.extra[noRetryExtra], isTrue);
    expect(seen.connectTimeout, const Duration(seconds: 8));
  });

  group('jwtSubject', () {
    String jwt(Map<String, dynamic> claims) =>
        'h.${base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '')}.s';

    test('lit le sub', () {
      expect(jwtSubject(jwt({'sub': 'u1', 'role': 'proprio'})), 'u1');
    });

    test('rend null sur un jeton illisible', () {
      expect(jwtSubject(null), isNull);
      expect(jwtSubject('pas-un-jwt'), isNull);
      expect(jwtSubject('a.!!!.c'), isNull);
      expect(jwtSubject(jwt({'role': 'proprio'})), isNull);
    });
  });
}
