import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/reservation/business_logic/stay_quote.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';

StayQuote _quote(DateTime checkIn, DateTime checkOut) => StayQuote(
  dailyPrice: 20000,
  priceTiers: const [],
  stayType: StayType.fullDay,
  checkInAt: checkIn,
  checkOutAt: checkOut,
);

void main() {
  group('StayQuote.daysCount', () {
    test('24 h pile valent un jour', () {
      final quote = _quote(
        DateTime(2026, 10, 8, 12),
        DateTime(2026, 10, 9, 12),
      );
      expect(quote.daysCount, 1);
    });

    test('quelques secondes au-delà de 24 h restent dans la tolérance', () {
      // La règle de départ tardif offre l'heure qui suit : un dépassement de
      // quelques secondes n'entame plus un second jour, au serveur non plus.
      final quote = _quote(
        DateTime(2026, 10, 8, 10, 15, 42),
        DateTime(2026, 10, 9, 10, 16),
      );
      expect(quote.daysCount, 1);
      expect(quote.lateCheckout, isFalse);
    });

    test('lundi 12h → mardi 16h : un jour et une demi-journée', () {
      final quote = _quote(
        DateTime(2026, 10, 19, 12),
        DateTime(2026, 10, 20, 16),
      );
      expect(quote.daysCount, 1);
      expect(quote.lateCheckout, isTrue);
      expect(quote.lateCheckoutFee, 10000);
      expect(quote.expectedAmount, 30000);
      expect(quote.agreedAmount(15000), 22500);
    });

    test('au-delà de la demi-journée, le jour entamé est dû', () {
      final quote = _quote(
        DateTime(2026, 10, 19, 12),
        DateTime(2026, 10, 20, 19),
      );
      expect(quote.daysCount, 2);
      expect(quote.lateCheckout, isFalse);
    });

    test('la règle du bien remplace les valeurs par défaut', () {
      final quote = StayQuote(
        dailyPrice: 20000,
        priceTiers: const [],
        stayType: StayType.fullDay,
        checkInAt: DateTime(2026, 10, 19, 12),
        checkOutAt: DateTime(2026, 10, 20, 12, 30),
        lateCheckoutPolicy: const LateCheckoutPolicy(
          graceMinutes: 0,
          halfDayHours: 0,
        ),
      );
      expect(quote.daysCount, 2);
    });

    test('explicitDaysCount prime sur le décompte automatique horaire', () {
      // Arrivée à 12:10 et départ le lendemain à 15:00 : plus de 24h,
      // mais le propriétaire a choisi de facturer 1 jour.
      final quote = StayQuote(
        dailyPrice: 20000,
        priceTiers: const [],
        stayType: StayType.fullDay,
        checkInAt: DateTime(2026, 10, 8, 12, 10),
        checkOutAt: DateTime(2026, 10, 9, 15, 0),
        explicitDaysCount: 1,
      );
      expect(quote.daysCount, 1);
      // Les 2h50 au-delà du jour choisi se paient en demi-journée.
      expect(quote.lateCheckout, isTrue);
    });

    test('les séjours infra-journaliers restent figés à 1 unité', () {
      final quote = StayQuote(
        dailyPrice: 20000,
        priceTiers: const [],
        stayType: StayType.halfDay,
        checkInAt: DateTime(2026, 10, 8, 12, 0),
        checkOutAt: DateTime(2026, 10, 8, 18, 0),
        explicitDaysCount: 3,
      );
      expect(quote.daysCount, 1);
    });
  });
}
