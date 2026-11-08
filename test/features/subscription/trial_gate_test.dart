import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/auth/data/models/subscription_status_model.dart';
import 'package:resi_africa/features/subscription/business_logic/plan_state.dart';
import 'package:resi_africa/features/subscription/business_logic/trial_choice_cubit.dart';
import 'package:resi_africa/features/subscription/business_logic/trial_gate.dart';
import 'package:resi_africa/features/subscription/data/models/plan_access.dart';
import 'package:resi_africa/features/subscription/data/models/subscription_plan_model.dart';

void main() {
  group('SubscriptionStatusModel — essai', () {
    test('lit le choix requis, le palier essayé et le palier échu', () {
      final status = SubscriptionStatusModel.fromJson({
        'is_trial': true,
        'trial_choice_required': false,
        'ended_trial_tier': null,
        'subscription': {'status': 'trial', 'plan_tier': 'pro'},
      });

      expect(status.trialChoiceRequired, isFalse);
      expect(status.trialTier, 'pro');
      expect(status.endedTrialTier, isNull);
    });

    test('un serveur antérieur ouvrait l’essai lui-même : rien à choisir', () {
      final status = SubscriptionStatusModel.fromJson({'is_trial': false});

      expect(status.trialChoiceRequired, isFalse);
      expect(status.trialTier, isNull);
      expect(status.endedTrialTier, isNull);
    });

    test(
      'hors essai, le palier de l’abonnement n’est pas celui d’un essai',
      () {
        final status = SubscriptionStatusModel.fromJson({
          'is_trial': false,
          'ended_trial_tier': 'pro_plus',
          'subscription': {'status': 'active', 'plan_tier': 'pro'},
        });

        expect(status.trialTier, isNull);
        expect(status.endedTrialTier, 'pro_plus');
      },
    );
  });

  group('trialOffers', () {
    SubscriptionPlanModel plan(String id, PlanAccess access, double price) =>
        SubscriptionPlanModel(
          id: id,
          name: id,
          price: price,
          durationDays: 30,
          access: access,
        );

    test('un forfait par palier, le moins cher, Pro avant Pro+', () {
      final offers = trialOffers([
        plan('plus-90', PlanAccess.proPlus, 14000),
        plan('pro-30', PlanAccess.pro, 3000),
        plan('plus-30', PlanAccess.proPlus, 5000),
        plan('pro-90', PlanAccess.pro, 8500),
      ]);

      expect(offers.map((o) => o.id), ['pro-30', 'plus-30']);
    });

    test('un palier sans forfait actif n’est pas proposé', () {
      final offers = trialOffers([plan('plus-30', PlanAccess.proPlus, 5000)]);

      expect(offers.map((o) => o.id), ['plus-30']);
    });
  });

  group('trialGate', () {
    test('rien de connu : aucun écran imposé', () {
      expect(
        trialGate(const PlanUnknown(), role: 'proprio', endedSeen: false),
        TrialGate.none,
      );
    });

    test('un propriétaire qui n’a pas choisi est retenu sur le choix', () {
      const state = PlanKnown(PlanAccess.free, trialChoiceRequired: true);

      expect(
        trialGate(state, role: 'proprio', endedSeen: false),
        TrialGate.choose,
      );
    });

    test('un essai terminé s’annonce une fois', () {
      const state = PlanKnown(PlanAccess.free, endedTrialTier: PlanAccess.pro);

      expect(
        trialGate(state, role: 'proprio', endedSeen: false),
        TrialGate.ended,
      );
      expect(
        trialGate(state, role: 'proprio', endedSeen: true),
        TrialGate.none,
      );
    });

    test('un gérant n’a rien à choisir ni à annoncer', () {
      const state = PlanKnown(
        PlanAccess.free,
        trialChoiceRequired: true,
        endedTrialTier: PlanAccess.pro,
      );

      expect(
        trialGate(state, role: 'gerant', endedSeen: false),
        TrialGate.none,
      );
    });
  });
}
