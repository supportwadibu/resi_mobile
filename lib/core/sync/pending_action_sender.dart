import 'package:easy_localization/easy_localization.dart';

import '../../features/clients/data/models/client_model.dart';
import '../../features/clients/data/repositories/clients_repository.dart';
import '../../features/expense/data/models/expense_model.dart';
import '../../features/expense/data/repositories/expense_repository.dart';
import '../../features/reservation/data/models/reservation_model.dart';
import '../../features/reservation/data/repositories/reservation_repository.dart';
import '../error/failures.dart';
import '../offline/pending_action.dart';

/// Envoie au serveur une action mise en file, par le repository qui la porte.
///
/// Séparé de `SyncService` : le service décide de l'ordre et du sort des
/// refus, celui-ci traduit une charge utile en appel d'API.
class PendingActionSender {
  PendingActionSender(this._reservations, this._clients, this._expenses);

  final ReservationRepository _reservations;
  final ClientsRepository _clients;
  final ExpenseRepository _expenses;

  /// Envoie [action] sur l'élément [target], identifiant serveur déjà résolu.
  ///
  /// Rend l'identifiant serveur de l'élément créé, pour une création — de quoi
  /// rattacher les actions qui le visaient par son identifiant local.
  Future<String?> send(PendingAction action, String? target) async {
    final p = action.payload;

    switch (action.type) {
      case PendingActionType.bookingCheckOut:
        await _reservations.checkOut(
          _required(target),
          actualCheckOutAt: _date(p['actual_check_out_at']),
        );
        return null;

      case PendingActionType.bookingCheckOutEarly:
        await _reservations.checkOutEarly(
          _required(target),
          actualCheckOutAt: _date(p['actual_check_out_at'])!,
          finalAmount: p['final_amount'] as num?,
        );
        return null;

      case PendingActionType.bookingExtend:
        await _reservations.extend(
          _required(target),
          checkOutAt: _date(p['check_out_at'])!,
          receivedAmount: p['received_amount'] as num?,
        );
        return null;

      case PendingActionType.bookingUpdate:
        await _reservations.update(
          _required(target),
          propertyId: p['property_id'] as String,
          stayType: StayType.fromCode(p['stay_type'] as String?),
          checkInAt: _date(p['check_in_at'])!,
          checkOutAt: _date(p['check_out_at'])!,
          agreedAmount: (p['received_amount'] as num?)?.toDouble(),
          depositAmount: (p['deposit_amount'] as num?)?.toDouble() ?? 0,
          message: p['message'] as String? ?? '',
        );
        return null;

      case PendingActionType.clientCreate:
        final created = await _clients.create(
          fullName: p['full_name'] as String,
          phone: p['phone'] as String,
          whatsapp: p['whatsapp'] as String?,
          idDocumentType: ClientIdDocumentType.fromCode(
            p['id_document_type'] as String?,
          ),
          idDocumentNumber: p['id_document_number'] as String?,
          identity: _identity(p['identity']),
          documentFrontPath: action.filePaths['id_document_front'],
          documentBackPath: action.filePaths['id_document_back'],
        );
        final client = created.client;
        if (client == null) {
          // La fiche existe hors du périmètre du gérant : le serveur l'accuse
          // sans la livrer. Refus définitif, comme pour une réservation.
          throw AppFailure.forbidden(code: 'client_out_of_scope');
        }
        return client.id;

      case PendingActionType.clientUpdate:
        await _clients.update(
          _required(target),
          fullName: p['full_name'] as String?,
          phone: p['phone'] as String?,
          whatsapp: p['whatsapp'] as String?,
          idDocumentType: ClientIdDocumentType.fromCode(
            p['id_document_type'] as String?,
          ),
          idDocumentNumber: p['id_document_number'] as String?,
          identity: p.containsKey('identity') ? _identity(p['identity']) : null,
          status: p['status'] == null
              ? null
              : ClientStatus.fromCode(p['status'] as String?),
          documentFrontPath: action.filePaths['id_document_front'],
          documentBackPath: action.filePaths['id_document_back'],
        );
        return null;

      case PendingActionType.expenseCreate:
        final expense = await _expenses.create(
          CreateExpensePayload.fromJson(p),
          clientRequestId: action.id,
        );
        return expense.id;
    }
  }

  static String _required(String? target) {
    if (target == null || target.isEmpty) {
      throw AppFailure.localized(
        message: 'sync.missing_target'.tr(),
        statusCode: 422,
        code: 'missing_target',
      );
    }
    return target;
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static ClientIdentity _identity(Object? raw) => raw is Map<String, dynamic>
      ? ClientIdentity.fromJson(raw)
      : ClientIdentity.empty;
}
