import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';
import 'package:resi_africa/features/reservation/business_logic/add_reservation_state.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';

/// Séjour de [days] jours pleins à 20 000 F, sur la grille [tiers].
AddReservationState _stay({
  required int days,
  List<PriceTier> tiers = const [],
  StayType stayType = StayType.fullDay,
  double dailyPrice = 20000,
}) {
  final checkIn = DateTime(2026, 3, 1, 12);

  return AddReservationState(
    mode: ReservationMode.checkIn,
    dailyPrice: dailyPrice,
    priceTiers: tiers,
    stayType: stayType,
    checkInAt: checkIn,
    checkOutAt: checkIn.add(Duration(days: days)),
  );
}

void main() {
  group('AddReservationState.discountPercent', () {
    test('aucune remise sans palier — le cas des biens historiques', () {
      expect(_stay(days: 30).discountPercent, 0);
    });

    test('aucune remise tant que la durée n’atteint aucun palier', () {
      final state = _stay(
        days: 5,
        tiers: const [PriceTier(minDays: 7, discountPercent: 10)],
      );

      expect(state.discountPercent, 0);
    });

    test('retient le palier le plus avantageux atteint, pas le dernier', () {
      // Grille volontairement désordonnée : un bien enregistré avant la
      // normalisation peut porter ses paliers dans n'importe quel ordre.
      final state = _stay(
        days: 20,
        tiers: const [
          PriceTier(minDays: 14, discountPercent: 15),
          PriceTier(minDays: 7, discountPercent: 10),
          PriceTier(minDays: 30, discountPercent: 25),
        ],
      );

      expect(state.discountPercent, 15);
    });

    test('un palier atteint tout juste s’applique', () {
      final state = _stay(
        days: 7,
        tiers: const [PriceTier(minDays: 7, discountPercent: 10)],
      );

      expect(state.discountPercent, 10);
    });

    test('un séjour infra-journalier n’atteint aucun palier', () {
      // La demi-journée et le passage valent un jour : aucune grille de durée
      // ne peut s'y appliquer, le palier minimal du serveur étant de 2 jours.
      final state = _stay(
        days: 10,
        stayType: StayType.halfDay,
        tiers: const [PriceTier(minDays: 7, discountPercent: 10)],
      );

      expect(state.discountPercent, 0);
    });
  });

  group('AddReservationState.expectedAmount', () {
    test('plein tarif quand aucun palier ne joue', () {
      expect(_stay(days: 3).expectedAmount, 60000);
    });

    test('applique la remise du palier atteint', () {
      final state = _stay(
        days: 10,
        tiers: const [PriceTier(minDays: 7, discountPercent: 10)],
      );

      expect(state.expectedAmount, 180000);
    });

    test('arrondit au franc, comme le serveur', () {
      // 3 × 3 333 = 9 999, moins 15 % → 8 499,15 : le FCFA n'a pas de
      // subdivision, un montant à virgule se propagerait jusqu'à la caisse.
      final state = _stay(
        days: 3,
        dailyPrice: 3333,
        tiers: const [PriceTier(minDays: 2, discountPercent: 15)],
      );

      expect(state.expectedAmount, 8499);
    });

    test('le montant négocié prime sur le montant remisé', () {
      final state = _stay(
        days: 10,
        tiers: const [PriceTier(minDays: 7, discountPercent: 10)],
      ).copyWith(agreedUnitPrice: 15000);

      expect(state.effectiveAmount, 150000);
    });
  });

  group('AddReservationState : prix convenu par unité', () {
    test('le total est le prix par jour multiplié par les jours', () {
      final state = _stay(days: 3).copyWith(agreedUnitPrice: 12000);

      expect(state.receivedAmount, 36000);
      expect(state.effectiveAmount, 36000);
    });

    test('le total suit les dates sans ressaisie', () {
      final state = _stay(days: 3).copyWith(agreedUnitPrice: 12000);
      final longer = state.copyWith(
        checkOutAt: state.checkInAt!.add(const Duration(days: 5)),
      );

      expect(longer.receivedAmount, 60000);
    });

    test('une demi-journée ou un passage valent une unité', () {
      final state = _stay(
        days: 1,
        stayType: StayType.halfDay,
      ).copyWith(agreedUnitPrice: 7000);

      expect(state.receivedAmount, 7000);
    });

    test('sans prix convenu, le tarif s’applique', () {
      expect(_stay(days: 3).receivedAmount, isNull);
      expect(_stay(days: 3).effectiveAmount, 60000);
    });
  });
}
