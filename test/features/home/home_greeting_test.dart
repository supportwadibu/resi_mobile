import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/home/presentation/widgets/home/home_greeting.dart';

void main() {
  group('salutation selon l’heure', () {
    test('chaque heure de la journée a ses formules', () {
      expect(HomeGreeting.forHour(5), HomeGreeting.morning);
      expect(HomeGreeting.forHour(11), HomeGreeting.morning);
      expect(HomeGreeting.forHour(12), HomeGreeting.afternoon);
      expect(HomeGreeting.forHour(17), HomeGreeting.afternoon);
      expect(HomeGreeting.forHour(18), HomeGreeting.evening);
      expect(HomeGreeting.forHour(22), HomeGreeting.evening);
      expect(HomeGreeting.forHour(23), HomeGreeting.night);
      expect(HomeGreeting.forHour(0), HomeGreeting.night);
      expect(HomeGreeting.forHour(4), HomeGreeting.night);
    });

    test('jamais « Bonjour » au milieu de la nuit', () {
      final random = Random(1);
      for (var i = 0; i < 200; i++) {
        final s = HomeGreeting.salutation(DateTime(2026, 10, 1, 2), random);
        expect(s, isNot('Bonjour'));
        // Les listes portent des clés ; la salutation, elle, est traduite.
        expect(
          [...HomeGreeting.night, ...HomeGreeting.anytime].map((k) => k.tr()),
          contains(s),
        );
      }
    });

    test('le tirage varie les formules', () {
      final random = Random(7);
      final seen = {
        for (var i = 0; i < 200; i++)
          HomeGreeting.salutation(DateTime(2026, 10, 1, 9), random),
      };
      expect(seen.length, greaterThan(3));
    });
  });
}
