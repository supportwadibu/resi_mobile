import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/core/deep_links/payment_return_links.dart';
import 'package:resi_africa/features/subscription/data/models/subscription_plan_model.dart';
import 'package:resi_africa/features/wallet/data/models/wallet_model.dart';

void main() {
  group('PaymentReturnLinks.parse', () {
    test('lit le succès et l’échec posés par la page du site', () {
      expect(
        PaymentReturnLinks.parse(Uri.parse('resi://abonnement?statut=succes')),
        PaymentReturn.success,
      );
      expect(
        PaymentReturnLinks.parse(Uri.parse('resi://abonnement?statut=echec')),
        PaymentReturn.failure,
      );
    });

    test('ignore un lien qui n’est pas un retour de paiement', () {
      expect(
        PaymentReturnLinks.parse(Uri.parse('resi://autre?statut=succes')),
        isNull,
      );
      expect(
        PaymentReturnLinks.parse(Uri.parse('https://resi.africa/abonnement')),
        isNull,
      );
      expect(
        PaymentReturnLinks.parse(Uri.parse('resi://abonnement?statut=x')),
        isNull,
      );
    });
  });

  group('SubscriptionOptionsModel', () {
    test('lit le remboursement et les montées chiffrées', () {
      final options = SubscriptionOptionsModel.fromJson(const {
        'renewable': false,
        'cancellable': true,
        'refund_amount': 2666,
        'remaining_days': 16,
        'upgrades': [
          {
            'plan_id': 'plan_pro_plus',
            'plan_tier': 'pro_plus',
            'price': 5000,
            'amount': 3400,
          },
        ],
      });

      expect(options.renewable, isFalse);
      expect(options.cancellable, isTrue);
      expect(options.refundAmount, 2666);
      expect(options.remainingDays, 16);
      expect(options.upgrades, {'plan_pro_plus': 3400});
    });

    test('un serveur antérieur laisse l’écran payer sans résilier', () {
      final options = SubscriptionOptionsModel.fromJson(const {});

      expect(options.renewable, isTrue);
      expect(options.cancellable, isFalse);
      expect(options.upgrades, isEmpty);
    });
  });

  group('WithdrawalRules.feeFor', () {
    test('la part remboursée sort sans frais, comme au serveur', () {
      expect(WithdrawalRules.feeFor(10000), 100);
      expect(WithdrawalRules.feeFor(10000, feeFreeBalance: 2666), 74);
      expect(WithdrawalRules.feeFor(2000, feeFreeBalance: 2666), 0);
    });
  });
}
