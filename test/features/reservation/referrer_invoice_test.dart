import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:resi_africa/features/reservation/business_logic/add_reservation_state.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';
import 'package:resi_africa/features/reservation/data/services/invoice_pdf_service.dart';

Map<String, dynamic> _booking([Map<String, dynamic> extra = const {}]) => {
  'id': 'abc123def456',
  'property_id': 'p1',
  'client_id': 'c1',
  'status': 'completed',
  'start_date': '2026-09-20T12:00:00Z',
  'end_date': '2026-09-23T12:00:00Z',
  'check_in_at': '2026-09-20T12:00:00Z',
  'check_out_at': '2026-09-23T12:00:00Z',
  'days_count': 3,
  'daily_price': 20000,
  'total_amount': 54000,
  'discount_amount': 6000,
  'received_amount': 54000,
  'client': {'id': 'c1', 'full_name': 'Awa Koné', 'phone': '0700000000'},
  ...extra,
};

void main() {
  setUpAll(() => initializeDateFormatting('fr'));

  group('ReservationModel — apporteur', () {
    test('lit l’apporteur et sa commission figée', () {
      final reservation = ReservationModel.fromJson(
        _booking({
          'referrer': {'name': 'Koffi', 'phone': '0701020304'},
          'referrer_commission_rate': 0.1,
          'referrer_commission_amount': 5400,
        }),
      );

      expect(reservation.referrer?.name, 'Koffi');
      expect(reservation.referrer?.phone, '0701020304');
      expect(reservation.referrerCommissionRate, 0.1);
      expect(reservation.referrerCommissionAmount, 5400);
    });

    test('une réservation sans apporteur — ou antérieure — n’en porte pas', () {
      final reservation = ReservationModel.fromJson(_booking());

      expect(reservation.referrer, isNull);
      expect(reservation.referrerCommissionAmount, 0);
    });
  });

  group('AddReservationState — commission annoncée', () {
    const base = AddReservationState(
      mode: ReservationMode.checkIn,
      receivedAmount: 45000,
    );

    test('10 % du montant convenu, arrondi au franc', () {
      final state = base.copyWith(
        hasReferrerEnabled: true,
        referrerName: 'Koffi',
      );
      expect(state.hasReferrer, isTrue);
      expect(state.referrerCommission, 4500);
    });

    test('sans nom d’apporteur, aucune commission', () {
      expect(base.hasReferrer, isFalse);
      expect(
        base
            .copyWith(hasReferrerEnabled: true, referrerName: ' ')
            .referrerCommission,
        0,
      );
    });

    test('bascule éteinte, le nom saisi est ignoré', () {
      final state = base.copyWith(referrerName: 'Koffi');
      expect(state.hasReferrer, isFalse);
      expect(state.referrerCommission, 0);
    });
  });

  group('InvoicePdfService', () {
    test('numéro stable, dérivé de l’identifiant', () {
      final reservation = ReservationModel.fromJson(_booking());
      expect(InvoicePdfService.invoiceNumber(reservation), 'RESI-ABC123DE');
    });

    test(
      'porte le total, la remise, et le reste dû seulement avec acompte',
      () {
        final paid = InvoicePdfService.lines(
          ReservationModel.fromJson(_booking()),
        );
        final keys = paid.map((line) => line.labelKey).toList();

        expect(keys, contains('invoice.total'));
        expect(keys, contains('invoice.discount'));
        expect(keys, isNot(contains('invoice.balance')));
        expect(
          paid.firstWhere((line) => line.labelKey == 'invoice.total').value,
          contains('54'),
        );

        final withDeposit = InvoicePdfService.lines(
          ReservationModel.fromJson(_booking({'deposit_amount': 20000})),
        );
        final balance = withDeposit.firstWhere(
          (line) => line.labelKey == 'invoice.balance',
        );
        expect(balance.strong, isTrue);
        expect(balance.value, contains('34'));
      },
    );

    test('le PDF se génère sans réseau', () async {
      final bytes = await const InvoicePdfService().build(
        reservation: ReservationModel.fromJson(_booking()),
        issuer: const InvoiceIssuer(
          name: 'Résidence Adja',
          phone: '0102030405',
        ),
        issuedAt: DateTime(2026, 9, 26),
      );

      // En-tête « %PDF » : le document est bien produit.
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });
  });
}
