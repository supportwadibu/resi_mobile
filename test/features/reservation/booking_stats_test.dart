import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/reservation/data/models/booking_stats_model.dart';

void main() {
  group('BookingStatsModel.fromJson', () {
    test('lit les chiffres du tableau de bord', () {
      final stats = BookingStatsModel.fromJson({
        'taux_occupation': 0.78,
        'upcoming': 4,
        'in_progress': 12,
        'revenue': {
          'current_month': 1260840,
          'previous_month': 980200,
          'growth_percent': 28.6,
        },
      });

      expect(stats.upcoming, 4);
      expect(stats.inProgress, 12);
      expect(stats.revenue.currentMonth, 1260840);
      expect(stats.revenue.previousMonth, 980200);
      expect(stats.revenue.growthPercent, 28.6);
    });

    test('arrondit le taux d’occupation en pourcentage entier', () {
      final stats = BookingStatsModel.fromJson({'taux_occupation': 0.784});

      expect(stats.occupancyPercent, 78);
    });

    test('une croissance nulle reste indéfinie plutôt que zéro', () {
      final stats = BookingStatsModel.fromJson({
        'revenue': {
          'current_month': 100000,
          'previous_month': 0,
          'growth_percent': null,
        },
      });

      expect(stats.revenue.growthPercent, isNull);
      expect(stats.revenue.previousMonth, 0);
    });

    test('un payload incomplet se replie sur des zéros', () {
      final stats = BookingStatsModel.fromJson(const {});

      expect(stats.tauxOccupation, 0);
      expect(stats.upcoming, 0);
      expect(stats.inProgress, 0);
      expect(stats.revenue.currentMonth, 0);
      expect(stats.revenue.growthPercent, isNull);
    });
  });
}
