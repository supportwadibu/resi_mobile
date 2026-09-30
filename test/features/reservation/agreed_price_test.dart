import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/reservation/business_logic/agreed_price.dart';

void main() {
  group('AgreedPrice.discount', () {
    test('l’écart entre tarif et prix convenu est une remise', () {
      expect(AgreedPrice.discount(expected: 220000, agreed: 200000), 20000);
    });

    test('sans prix convenu, aucune remise', () {
      expect(AgreedPrice.discount(expected: 220000, agreed: null), 0);
    });

    test('un prix au-dessus du tarif ne crée pas de remise négative', () {
      expect(AgreedPrice.discount(expected: 100000, agreed: 120000), 0);
    });
  });

  group('AgreedPrice.looksLikePayment', () {
    test('15 000 F convenus pour 220 000 F attendus : sans doute un versement',
        () {
      // Le cas de la fiche signalée : un séjour de 11 jours enregistré à
      // 15 000 F, avec 205 000 F de « remise ».
      expect(
        AgreedPrice.looksLikePayment(expected: 220000, agreed: 15000),
        isTrue,
      );
    });

    test('une remise ordinaire ne déclenche rien', () {
      expect(
        AgreedPrice.looksLikePayment(expected: 220000, agreed: 180000),
        isFalse,
      );
    });

    test('sans prix saisi, rien à signaler', () {
      expect(
        AgreedPrice.looksLikePayment(expected: 220000, agreed: null),
        isFalse,
      );
    });

    test('un tarif inconnu ne déclenche rien', () {
      expect(AgreedPrice.looksLikePayment(expected: 0, agreed: 5000), isFalse);
    });
  });
}
