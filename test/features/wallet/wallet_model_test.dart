import 'package:flutter_test/flutter_test.dart';
import 'package:resi_africa/features/wallet/data/models/wallet_model.dart';

void main() {
  group('WithdrawalRules', () {
    test('1 % de frais, au franc supérieur comme au serveur', () {
      expect(WithdrawalRules.feeFor(10000), 100);
      expect(WithdrawalRules.feeFor(1050), 11);
      expect(WithdrawalRules.feeFor(0), 0);
    });
  });

  group('WalletModel', () {
    test('un portefeuille sans résidence est le portefeuille général', () {
      final wallet = WalletModel.fromJson({
        'id': 'owner_o1',
        'residence_id': null,
        'balance': 25000,
      });
      expect(wallet.residenceId, isNull);
      expect(wallet.balance, 25000);
      expect(wallet.pendingWithdrawals, 0);
    });
  });

  group('WalletTransactionModel', () {
    test('un mouvement signé garde son signe et son solde après', () {
      final debit = WalletTransactionModel.fromJson({
        'id': 't1',
        'type': 'withdrawal',
        'amount': -10000,
        'balance_after': 5000,
        'created_at': '2026-10-20T10:00:00.000Z',
      });
      expect(debit.type, WalletTransactionType.withdrawal);
      expect(debit.amount, -10000);
      expect(debit.isCredit, isFalse);
      expect(debit.balanceAfter, 5000);
    });

    test('un type inconnu d’un serveur plus récent reste lisible', () {
      final unknown = WalletTransactionModel.fromJson({
        'id': 't2',
        'type': 'bonus',
        'amount': 500,
        'created_at': '2026-10-20T10:00:00.000Z',
      });
      expect(unknown.type, WalletTransactionType.other);
      expect(unknown.isCredit, isTrue);
    });

    test('la page dit s’il en reste une suivante', () {
      final page = WalletTransactionPage.fromJson({
        'data': [
          {'id': 't1', 'type': 'credit', 'amount': 2000},
        ],
        'meta': {'total': 25, 'perPage': 20, 'currentPage': 1, 'lastPage': 2},
      });
      expect(page.items, hasLength(1));
      expect(page.items.single.type, WalletTransactionType.credit);
      expect(page.hasMore, isTrue);
    });
  });

  group('PayoutSettings', () {
    test('lit le minimum réglé au backoffice et les numéros Wave', () {
      final settings = PayoutSettings.fromJson({
        'minimum_withdrawal': 5000,
        'fee_rate': 0.01,
        'numbers': [
          {'slot': 2, 'phone': '0500000002', 'holder_name': 'Awa'},
          {'slot': 1, 'phone': '0700000001', 'holder_name': null},
        ],
      });
      expect(settings.minimumWithdrawal, 5000);
      expect(settings.numbers.map((n) => n.slot), [1, 2]);
      expect(settings.numberAt(2)?.holderName, 'Awa');
      expect(settings.numberAt(1)?.holderName, isNull);
    });

    test('un serveur antérieur garde le minimum historique', () {
      final settings = PayoutSettings.fromJson(const {});
      expect(settings.minimumWithdrawal, WithdrawalRules.minimum);
      expect(settings.numbers, isEmpty);
    });
  });

  group('WithdrawalModel', () {
    test('un statut inconnu reste en attente', () {
      final withdrawal = WithdrawalModel.fromJson({
        'id': 'w1',
        'amount': 10000,
        'fee': 100,
        'net_amount': 9900,
        'status': 'paid',
        'created_at': '2026-10-20T10:00:00.000Z',
      });
      expect(withdrawal.status, WithdrawalStatus.paid);
      expect(withdrawal.netAmount, 9900);
      expect(WithdrawalStatus.fromCode('???'), WithdrawalStatus.pending);
    });
  });
}
