import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:resi_africa/core/offline/pending_action.dart';
import 'package:resi_africa/core/offline/pending_overlay.dart';
import 'package:resi_africa/core/utils/phone_helper.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';
import 'package:resi_africa/features/reservation/data/services/invoice_pdf_service.dart';

/// Entrée prévue le 10 octobre à 14 h, sortie le 12 à 12 h — en heure locale,
/// comme le comptoir la lit.
ReservationModel _reservation({
  ReservationStatus status = ReservationStatus.confirmed,
}) => ReservationModel(
  id: 'abc123def456',
  propertyId: 'p1',
  clientId: 'c1',
  status: status,
  startDate: DateTime(2026, 10, 10, 14),
  endDate: DateTime(2026, 10, 12, 12),
  daysCount: 2,
  totalAmount: 30000,
  dailyPrice: 20000,
  expectedAmount: 40000,
  receivedAmount: 30000,
  discountAmount: 10000,
  source: ReservationSource.offline,
  client: const ReservationClient(
    id: 'c1',
    fullName: 'Awa Koné',
    phone: '0700000000',
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('ReservationModel.canCheckIn', () {
    test('le jour J, même avant l’heure prévue, l’arrivée est proposée', () {
      expect(_reservation().canCheckIn(DateTime(2026, 10, 10, 8)), isTrue);
    });

    test('la veille, elle ne l’est pas', () {
      expect(_reservation().canCheckIn(DateTime(2026, 10, 9, 23)), isFalse);
    });

    test('après la sortie prévue, ni sur un séjour déjà ouvert', () {
      expect(_reservation().canCheckIn(DateTime(2026, 10, 12, 13)), isFalse);
      expect(
        _reservation(
          status: ReservationStatus.inProgress,
        ).canCheckIn(DateTime(2026, 10, 10, 15)),
        isFalse,
      );
    });
  });

  group('PhoneHelper.toWhatsApp', () {
    test('un numéro national reçoit l’indicatif', () {
      expect(PhoneHelper.toWhatsApp('07 01 02 03 04', 'CI'), '2250701020304');
    });

    test('un numéro déjà international n’est pas doublé', () {
      expect(PhoneHelper.toWhatsApp('+2250701020304', 'CI'), '2250701020304');
    });

    test('un numéro illisible n’ouvre rien', () {
      expect(PhoneHelper.toWhatsApp('12', 'CI'), isNull);
      expect(PhoneHelper.toWhatsApp(null, 'CI'), isNull);
    });
  });

  group('InvoicePdfService.receiptText', () {
    test('reprend le numéro, le client et le total de la facture', () {
      final text = InvoicePdfService.receiptText(
        _reservation(),
        issuer: const InvoiceIssuer(
          name: 'Résidence Adja',
          phone: '0102030405',
        ),
      );

      expect(text, contains(InvoicePdfService.invoiceNumber(_reservation())));
      expect(text, contains('Résidence Adja · 0102030405'));
      expect(text, contains('Awa Koné'));
      // Le total, ligne forte de la facture, part en gras WhatsApp.
      expect(
        RegExp(r'^\*.*30.000 F\*$', multiLine: true).hasMatch(text),
        isTrue,
      );
    });
  });

  group('file hors ligne — arrivée', () {
    test('une arrivée en file ouvre la réservation', () {
      final result = applyBookingAction(
        {'id': 'b1', 'status': 'confirmed'},
        PendingAction(
          id: 'a1',
          type: PendingActionType.bookingCheckIn,
          targetRef: 'b1',
          payload: const {'actual_check_in_at': '2026-10-10T09:00:00.000Z'},
          createdAt: DateTime(2026, 10, 10, 9),
        ),
      );

      expect(result['status'], 'in_progress');
      expect(result['actual_check_in_at'], '2026-10-10T09:00:00.000Z');
    });
  });
}
