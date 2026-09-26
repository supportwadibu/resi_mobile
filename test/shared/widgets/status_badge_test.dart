import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/status_badge.dart';

/// Verrouille la grammaire des statuts partagée avec le backoffice
/// (`STATUS_TONES`) : une couleur porte le même sens dans toutes les familles.
void main() {
  group('StatusTone', () {
    test('chaque ton correspond à son accent', () {
      expect(StatusTone.done.accent, AppAccent.green);
      expect(StatusTone.ongoing.accent, AppAccent.violet);
      expect(StatusTone.upcoming.accent, AppAccent.blue);
      expect(StatusTone.waiting.accent, AppAccent.amber);
      expect(StatusTone.stopped.accent, AppAccent.red);
      expect(StatusTone.idle.accent, AppAccent.neutral);
    });
  });

  group('StatusTones', () {
    test('réservations, comme BOOKING_TONES', () {
      expect(StatusTones.booking('confirmed'), StatusTone.upcoming);
      expect(StatusTones.booking('in_progress'), StatusTone.ongoing);
      expect(StatusTones.booking('completed'), StatusTone.done);
      expect(StatusTones.booking('cancelled'), StatusTone.stopped);
    });

    test('biens, comme PROPERTY_TONES', () {
      expect(StatusTones.property('draft'), StatusTone.idle);
      expect(StatusTones.property('published'), StatusTone.done);
      expect(StatusTones.property('reserved'), StatusTone.upcoming);
      expect(StatusTones.property('rented'), StatusTone.ongoing);
      expect(StatusTones.property('maintenance'), StatusTone.waiting);
      expect(StatusTones.property('inactive'), StatusTone.idle);
    });

    test('file hors ligne : attente ambre, refus rouge', () {
      expect(StatusTones.sync('pending'), StatusTone.waiting);
      expect(StatusTones.sync('conflict'), StatusTone.stopped);
      expect(StatusTones.sync('rejected'), StatusTone.stopped);
    });

    test('un code inconnu reste hors circuit', () {
      expect(StatusTones.booking('???'), StatusTone.idle);
      expect(StatusTones.property('???'), StatusTone.idle);
    });
  });
}
