import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';

ReservationModel _reservation({
  double expected = 60000,
  double received = 60000,
  int discountPercent = 0,
  ReservationSource source = ReservationSource.offline,
}) {
  return ReservationModel(
    id: 'b1',
    propertyId: 'p1',
    clientId: 'c1',
    status: ReservationStatus.inProgress,
    startDate: DateTime.utc(2026, 10, 10, 12),
    endDate: DateTime.utc(2026, 10, 13, 12),
    daysCount: 3,
    dailyPrice: 20000,
    durationDiscountPercent: discountPercent,
    totalAmount: received,
    expectedAmount: expected,
    receivedAmount: received,
    source: source,
  );
}

void main() {
  group('ReservationModel.extensionDailyRate', () {
    test('un prix négocié se prolonge au tarif journalier convenu', () {
      // 3 jours à 45 000 F au lieu de 60 000 F : 15 000 F le jour ajouté,
      // comme le serveur le facturera.
      final reservation = _reservation(received: 45000);
      expect(reservation.hasNegotiatedPrice, isTrue);
      expect(reservation.extensionDailyRate, 15000);
    });

    test('sans négociation, la grille remisée s’applique', () {
      final reservation = _reservation(discountPercent: 10);
      expect(reservation.hasNegotiatedPrice, isFalse);
      expect(reservation.extensionDailyRate, 18000);
    });

    test('une réservation en ligne suit la grille', () {
      final reservation = _reservation(
        received: 45000,
        source: ReservationSource.online,
      );
      expect(reservation.extensionDailyRate, 20000);
    });
  });
}
