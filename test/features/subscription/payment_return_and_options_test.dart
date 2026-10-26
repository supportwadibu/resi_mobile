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

    test('lit l’issue d’une résiliation et le crédit disponible', () {
      final options = SubscriptionOptionsModel.fromJson(const {
        'cancellable': true,
        'cancel_mode': 'partial_refund',
        'refund_amount': 3000,
        'refund_credit': 2000,
        'access_ends_at': '2026-10-20T10:00:00.000Z',
        'credit': {'amount': 2000, 'expires_at': '2027-01-18T10:00:00.000Z'},
        'wave_fee_rate': 0.01,
      });

      expect(options.cancelMode, CancelMode.partialRefund);
      expect(options.refundAmount, 3000);
      expect(options.refundCredit, 2000);
      expect(options.accessEndsAt, isNotNull);
      expect(options.credit?.amount, 2000);
    });

    test('le paiement déduit le crédit et ajoute 1 % de frais Wave', () {
      final options = SubscriptionOptionsModel.fromJson(const {
        'credit': {'amount': 2000, 'expires_at': '2099-01-01T00:00:00.000Z'},
        'wave_fee_rate': 0.01,
      });

      final pro = options.quoteFor(planId: 'pro', price: 3000);
      expect(pro.credit, 2000);
      expect(pro.amount, 1000);
      expect(pro.fee, 10);
      expect(pro.total, 1010);

      final plain = SubscriptionOptionsModel.none.quoteFor(
        planId: 'pro_plus',
        price: 5000,
      );
      expect(plain.credit, 0);
      expect(plain.fee, 50);
      expect(plain.total, 5050);
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
