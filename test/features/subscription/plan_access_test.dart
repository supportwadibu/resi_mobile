import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/api/plan_signals.dart';
import 'package:resi_africa/core/error/failures.dart';
import 'package:resi_africa/core/sync/sync_service.dart';
import 'package:resi_africa/features/auth/data/models/subscription_status_model.dart';
import 'package:resi_africa/features/subscription/data/models/plan_access.dart';
import 'package:resi_africa/features/subscription/data/models/subscription_plan_model.dart';

void main() {
  group('PlanAccess', () {
    test('lit plan_access de l’API ; null vaut compte inactif', () {
      expect(PlanAccess.fromApi('full'), PlanAccess.full);
      expect(PlanAccess.fromApi('basic'), PlanAccess.basic);
      expect(PlanAccess.fromApi(null), PlanAccess.inactive);
      // Un code inconnu ne doit rien ouvrir que l'API refuserait ensuite.
      expect(PlanAccess.fromApi('gold'), PlanAccess.inactive);
    });

    test('le cache illisible vaut « rien de connu »', () {
      expect(PlanAccess.fromCache('basic'), PlanAccess.basic);
      expect(PlanAccess.fromCache(null), isNull);
      expect(PlanAccess.fromCache('???'), isNull);
    });
  });

  group('SubscriptionStatusModel.planAccess', () {
    test(
      'un serveur antérieur aux forfaits ne bloquait rien : accès complet',
      () {
        final status = SubscriptionStatusModel.fromJson({'can_operate': true});
        expect(status.planAccess, 'full');
      },
    );

    test('un plan_access nul explicite reste nul : compte inactif', () {
      final status = SubscriptionStatusModel.fromJson({'plan_access': null});
      expect(PlanAccess.fromApi(status.planAccess), PlanAccess.inactive);
    });
  });

  group('SubscriptionPlanModel', () {
    test('un plan sans palier est lu complet, comme le fait le serveur', () {
      final plan = SubscriptionPlanModel.fromJson({
        'id': 'p1',
        'name': 'Ancien plan',
        'price': 5000,
      });
      expect(plan.isFull, isTrue);
      expect(plan.durationDays, 30);
    });

    test('lit le palier basic', () {
      final plan = SubscriptionPlanModel.fromJson({
        'id': 'p2',
        'name': 'Forfait 3 000 F',
        'price': 3000,
        'duration_days': 30,
        'tier': 'basic',
      });
      expect(plan.isFull, isFalse);
    });
  });

  group('PlanSignals', () {
    test('traduit les refus d’abonnement, ignore les autres codes', () async {
      final signals = PlanSignals();
      final received = <PlanAccess>[];
      final sub = signals.stream.listen(received.add);

      signals
        ..report('subscription_required')
        ..report('plan_upgrade_required')
        ..report('out_of_scope')
        ..report(null);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(received, [PlanAccess.inactive, PlanAccess.basic]);
    });
  });

  group('classifyFailure — refus d’abonnement', () {
    test('une saisie refusée faute d’abonnement reste en file', () {
      final failure = AppFailure.forbidden(
        message: 'Votre abonnement est inactif.',
        code: 'subscription_required',
      );

      expect(failure.isSubscriptionRequired, isTrue);
      expect(classifyFailure(failure), FailureDisposition.retry);
    });

    test('même règle pour un palier insuffisant (gérant d’un 3 000 F)', () {
      final failure = AppFailure.forbidden(code: 'plan_upgrade_required');

      expect(failure.isPlanUpgradeRequired, isTrue);
      expect(classifyFailure(failure), FailureDisposition.retry);
    });

    test('un autre 403 garde son sort', () {
      final failure = AppFailure.forbidden(code: 'out_of_scope');
      expect(classifyFailure(failure), FailureDisposition.rejected);
    });
  });
}
