import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/reservation/data/models/early_check_out_quote.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';

/// Réservation au format de l'API : la règle portée est celle de
/// `api/app/features/bookings/early_check_out.ts`, et ses entrées doivent être
/// celles que le serveur lit.
ReservationModel _booking({
  String stayType = 'full_day',
  int? daysCount = 5,
  double paid = 50000,
}) => ReservationModel.fromJson({
  'id': 'b1',
  'status': 'in_progress',
  'stay_type': stayType,
  'start_date': '2026-10-01T12:00:00.000Z',
  'check_in_at': '2026-10-01T12:00:00.000Z',
  'end_date': '2026-10-06T12:00:00.000Z',
  'check_out_at': '2026-10-06T12:00:00.000Z',
  'days_count': ?daysCount,
  'total_amount': paid,
  'received_amount': paid,
});

void main() {
  final now = DateTime.utc(2026, 10, 3, 18);

  test('tout jour entamé reste dû — 2 jours et 3 heures en facturent 3', () {
    final quote = EarlyCheckOutQuote.estimate(
      _booking(),
      DateTime.utc(2026, 10, 3, 15),
      now: now,
    );

    expect(quote.plannedDays, 5);
    expect(quote.billedDays, 3);
    expect(quote.paidAmount, 50000);
    expect(quote.proposedAmount, 30000);
    expect(quote.refundAmount, 20000);
  });

  test('le prorata porte sur le montant réglé, arrondi au franc', () {
    final quote = EarlyCheckOutQuote.estimate(
      _booking(daysCount: 3, paid: 10000),
      DateTime.utc(2026, 10, 2, 11),
      now: now,
    );

    // 10 000 × 1 / 3 = 3 333,33…
    expect(quote.proposedAmount, 3333);
  });

  test('une demi-journée est indivisible', () {
    final quote = EarlyCheckOutQuote.estimate(
      _booking(stayType: 'half_day', daysCount: 1, paid: 8000),
      DateTime.utc(2026, 10, 1, 15),
      now: now,
    );

    expect(quote.proposedAmount, 8000);
    expect(quote.refundAmount, 0);
  });

  test('sans days_count, la durée est recomptée sur la période', () {
    final quote = EarlyCheckOutQuote.estimate(
      _booking(daysCount: null),
      DateTime.utc(2026, 10, 3, 15),
      now: now,
    );

    expect(quote.plannedDays, 5);
  });

  test('refuse une sortie antérieure à l’entrée', () {
    expect(
      () => EarlyCheckOutQuote.estimate(
        _booking(),
        DateTime.utc(2026, 10, 1, 10),
        now: now,
      ),
      throwsA(
        isA<EarlyCheckOutRefusal>().having((e) => e.code, 'code', 'invalid_departure'),
      ),
    );
  });

  test('refuse une sortie dans le futur, au-delà de la dérive tolérée', () {
    expect(
      () => EarlyCheckOutQuote.estimate(
        _booking(),
        now.add(const Duration(minutes: 10)),
        now: now,
      ),
      throwsA(
        isA<EarlyCheckOutRefusal>().having((e) => e.code, 'code', 'departure_in_future'),
      ),
    );
    expect(
      () => EarlyCheckOutQuote.estimate(
        _booking(),
        now.add(const Duration(minutes: 3)),
        now: now,
      ),
      returnsNormally,
    );
  });

  test('refuse une sortie qui n’est pas anticipée', () {
    expect(
      () => EarlyCheckOutQuote.estimate(
        _booking(),
        DateTime.utc(2026, 10, 6, 12),
        now: DateTime.utc(2026, 10, 7),
      ),
      throwsA(
        isA<EarlyCheckOutRefusal>().having((e) => e.code, 'code', 'not_early_departure'),
      ),
    );
  });
}
