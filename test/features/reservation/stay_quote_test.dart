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

    test(
      'quelques secondes au-delà de 24 h entament un second jour, comme au serveur',
      () {
        // Entrée enregistrée à la seconde, sortie choisie à la minute : en
        // minutes entières, l'écran comptait 1 jour quand le serveur en
        // comptait 2.
        final quote = _quote(
          DateTime(2026, 10, 8, 10, 15, 42),
          DateTime(2026, 10, 9, 10, 16),
        );
        expect(quote.daysCount, 2);
      },
    );
  });
}
