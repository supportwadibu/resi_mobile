import 'package:uuid/uuid.dart';

import '../error/failures.dart';
import 'pending_action.dart';
import 'pending_action_store.dart';

/// Met une action du comptoir en file quand le réseau manque.
///
/// Les cubits suivent tous la même règle que la création de réservation :
/// envoi direct en ligne, mise en file sur une panne **réseau** seulement. Un
/// refus métier remonte toujours au propriétaire — le rejouer ne changerait
/// rien.
class OfflineActionQueue {
  OfflineActionQueue(this._store, {required Future<void> Function() onQueued})
    : _onQueued = onQueued;

  final PendingActionStore _store;

  /// Rafraîchit les compteurs du bandeau de synchronisation.
  final Future<void> Function() _onQueued;

  static const _uuid = Uuid();

  /// L'échec vient-il du transport plutôt que d'une réponse du serveur ?
  ///
  /// Même règle que la création de réservation : sans statut, ou 5xx. Un
  /// 4xx est une décision du serveur, à présenter telle quelle.
  static bool isNetworkFailure(AppFailure failure) {
    final code = failure.statusCode;
    return code == null || code >= 500;
  }

  /// Identifiant local d'un élément créé hors ligne.
  static String newLocalId() => '$localIdPrefix${_uuid.v4()}';

  Future<PendingAction> enqueue(
    PendingActionType type, {
    String? targetRef,
    required Map<String, dynamic> payload,
    Map<String, String> filePaths = const {},
  }) async {
    final action = PendingAction(
      id: _uuid.v4(),
      type: type,
      targetRef: targetRef,
      payload: payload,
      filePaths: filePaths,
      createdAt: DateTime.now(),
    );
    await _store.enqueue(action);
    await _onQueued();
    return action;
  }
}
