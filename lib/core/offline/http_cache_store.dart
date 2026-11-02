import 'package:sqflite/sqflite.dart';

import '../storage/app_database.dart';
import 'cache_keys.dart';

/// Réponse lue dans le cache, avec sa date.
class CachedBody {
  const CachedBody({required this.body, required this.cachedAt});

  final String body;
  final DateTime cachedAt;
}

/// Dernière réponse connue de chaque lecture.
class HttpCacheStore {
  HttpCacheStore(this._database);

  final AppDatabase _database;

  /// Réponse de la requête elle-même, ou à défaut de la même requête à
  /// d'autres dates (voir [CacheKeys.loose]).
  Future<CachedBody?> read(CacheKeys keys) async {
    final exact = await _read(keys.exact);
    if (exact != null) return exact;

    final loose = keys.loose;
    return loose == null ? null : _read(loose);
  }

  /// Enregistre [body] sous la clé exacte et, pour une lecture datée, sous la
  /// clé souple — qui retient ainsi la plus récente des périodes consultées.
  Future<void> write(
    CacheKeys keys, {
    required String path,
    required String body,
    DateTime? at,
  }) async {
    final db = await _database.database;
    final row = {
      'path': path,
      'body': body,
      'cached_at': (at ?? DateTime.now()).millisecondsSinceEpoch,
    };

    final batch = db.batch();
    for (final key in [keys.exact, ?keys.loose]) {
      batch.insert('http_cache', {
        'cache_key': key,
        ...row,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<CachedBody?> _read(String key) async {
    final db = await _database.database;
    final rows = await db.query(
      'http_cache',
      columns: ['body', 'cached_at'],
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    return CachedBody(
      body: rows.first['body']! as String,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(
        rows.first['cached_at']! as int,
      ),
    );
  }
}
