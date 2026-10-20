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
      expect(PlanAccess.fromApi('pro_plus'), PlanAccess.proPlus);
      expect(PlanAccess.fromApi('pro'), PlanAccess.pro);
      expect(PlanAccess.fromApi('free'), PlanAccess.free);
      expect(PlanAccess.fromApi(null), PlanAccess.inactive);
      // Un code inconnu ne doit rien ouvrir que l'API refuserait ensuite.
      expect(PlanAccess.fromApi('gold'), PlanAccess.inactive);
    });

    test('relit les paliers d’un serveur antérieur aux offres actuelles', () {
      // « basic » (3 000 F) est devenu Pro, « full » (5 000 F) Pro+.
      expect(PlanAccess.fromApi('basic'), PlanAccess.pro);
      expect(PlanAccess.fromApi('full'), PlanAccess.proPlus);
    });

    test('un palier ouvre ce qu’ouvrent les paliers inférieurs', () {
      expect(PlanAccess.proPlus.allows(PlanAccess.pro), isTrue);
      expect(PlanAccess.pro.allows(PlanAccess.free), isTrue);
      expect(PlanAccess.free.allows(PlanAccess.pro), isFalse);
      expect(PlanAccess.pro.allows(PlanAccess.proPlus), isFalse);
      expect(PlanAccess.inactive.allows(PlanAccess.free), isFalse);
    });

    test('le cache illisible vaut « rien de connu »', () {
      expect(PlanAccess.fromCache('basic'), PlanAccess.pro);
      expect(PlanAccess.fromCache('free'), PlanAccess.free);
      expect(PlanAccess.fromCache('inactive'), PlanAccess.inactive);
      expect(PlanAccess.fromCache(null), isNull);
      expect(PlanAccess.fromCache('???'), isNull);
    });
  });

  group('SubscriptionStatusModel.planAccess', () {
    test(
      'un serveur antérieur aux forfaits ne bloquait rien : accès complet',
      () {
        final status = SubscriptionStatusModel.fromJson({'can_operate': true});
        expect(PlanAccess.fromApi(status.planAccess), PlanAccess.proPlus);
      },
    );

    test('plan_tier prime sur plan_access, gardé pour les anciennes versions', () {
      final status = SubscriptionStatusModel.fromJson({
        'plan_access': 'basic',
        'plan_tier': 'free',
      });
      expect(PlanAccess.fromApi(status.planAccess), PlanAccess.free);
    });

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
      expect(plan.access, PlanAccess.proPlus);
      expect(plan.durationDays, 30);
    });

    test('lit le palier historique basic comme Pro', () {
      final plan = SubscriptionPlanModel.fromJson({
        'id': 'p2',
        'name': 'Forfait 3 000 F',
        'price': 3000,
        'duration_days': 30,
        'tier': 'basic',
      });
      expect(plan.access, PlanAccess.pro);
    });
  });

  group('PlanSignals', () {
    test('traduit les refus d’abonnement, ignore les autres codes', () async {
      final signals = PlanSignals();
      final received = <PlanRefusal>[];
      final sub = signals.stream.listen(received.add);

      signals
        ..report('subscription_required')
        ..report('plan_upgrade_required')
        ..report('out_of_scope')
        ..report(null);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(received, [PlanRefusal.inactive, PlanRefusal.upgradeRequired]);
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

    test('même règle pour un palier insuffisant (gérant sous Pro+)', () {
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
