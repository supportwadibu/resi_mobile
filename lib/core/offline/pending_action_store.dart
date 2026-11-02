import 'package:sqflite/sqflite.dart';

import '../storage/app_database.dart';
import 'pending_action.dart';

/// File des actions du comptoir saisies sans réseau.
class PendingActionStore {
  const PendingActionStore(this._database);

  final AppDatabase _database;

  Future<Database> get _db => _database.database;

  Future<void> enqueue(PendingAction action) async {
    final db = await _db;
    await db.insert(
      'pending_actions',
      action.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Toutes les actions, quel que soit leur état, dans l'ordre de saisie.
  /// Les conflits et refus comptent aussi pour l'affichage : le propriétaire
  /// doit voir ce qu'il a saisi tant qu'il n'a pas tranché.
  Future<List<PendingAction>> all() => _query();

  /// Actions à envoyer, dans l'ordre de saisie.
  Future<List<PendingAction>> queue() =>
      _query(state: PendingActionState.pending);

  Future<PendingAction?> find(String id) async {
    final db = await _db;
    final rows = await db.query(
      'pending_actions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : PendingAction.fromRow(rows.first);
  }

  /// Retire une action, une fois acceptée par le serveur — ou abandonnée par
  /// le propriétaire.
  Future<void> remove(String id) async {
    final db = await _db;
    await db.delete('pending_actions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> mark(
    String id, {
    required PendingActionState state,
    String? errorCode,
    String? errorMessage,
  }) async {
    final db = await _db;
    await db.update(
      'pending_actions',
      {
        'state': state.code,
        'error_code': errorCode,
        'error_message': errorMessage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> count(PendingActionState state) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM pending_actions WHERE state = ?',
      [state.code],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ── Identifiants locaux ───────────────────────────────────────────────────

  /// Retient l'identifiant serveur d'un élément créé hors ligne.
  Future<void> link(String localId, String remoteId) async {
    final db = await _db;
    await db.insert('local_refs', {
      'local_id': localId,
      'remote_id': remoteId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Identifiant serveur de [ref], `null` tant que l'élément n'est pas parti.
  ///
  /// Un identifiant serveur se rend tel quel. Un identifiant local se lit
  /// dans `local_refs`, puis dans `pending_clients` : un client créé avec une
  /// réservation hors ligne y reçoit son identifiant serveur, sans passer par
  /// cette file.
  Future<String?> resolve(String ref) async {
    if (!isLocalId(ref)) return ref;

    final db = await _db;
    final linked = await db.query(
      'local_refs',
      columns: ['remote_id'],
      where: 'local_id = ?',
      whereArgs: [ref],
      limit: 1,
    );
    if (linked.isNotEmpty) return linked.first['remote_id'] as String?;

    final client = await db.query(
      'pending_clients',
      columns: ['remote_id'],
      where: 'local_id = ? AND remote_id IS NOT NULL',
      whereArgs: [ref],
      limit: 1,
    );
    return client.isEmpty ? null : client.first['remote_id'] as String?;
  }

  Future<List<PendingAction>> _query({PendingActionState? state}) async {
    final db = await _db;
    final rows = await db.query(
      'pending_actions',
      where: state == null ? null : 'state = ?',
      whereArgs: state == null ? null : [state.code],
      orderBy: 'created_at ASC',
    );
    return rows.map(PendingAction.fromRow).nonNulls.toList(growable: false);
  }
}
