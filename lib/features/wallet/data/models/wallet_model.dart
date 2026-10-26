import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Portefeuille d'une résidence, tel que servi par `GET /proprio/wallets`.
///
/// L'argent que les clients ont payé par Wave pour la résidence : RESI l'a
/// reçu et le doit au propriétaire, qui le retire par une demande.
class WalletModel {
  const WalletModel({
    required this.id,
    required this.residenceId,
    required this.residenceName,
    required this.balance,
    required this.totalCredited,
    required this.totalWithdrawn,
    required this.pendingWithdrawals,
    this.feeFreeBalance = 0,
  });

  final String id;

  /// `null` : portefeuille général des biens hors résidence.
  final String? residenceId;
  final String? residenceName;

  /// Disponible au retrait. Les retraits en attente en sont déjà débités.
  final double balance;
  final double totalCredited;
  final double totalWithdrawn;
  final double pendingWithdrawals;

  /// Part de [balance] retirable sans frais : les remboursements
  /// d'abonnement. Absente d'un serveur antérieur : 0.
  final double feeFreeBalance;

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
    id: json['id'] as String? ?? '',
    residenceId: json['residence_id'] as String?,
    residenceName: json['residence_name'] as String?,
    balance: (json['balance'] as num?)?.toDouble() ?? 0,
    totalCredited: (json['total_credited'] as num?)?.toDouble() ?? 0,
    totalWithdrawn: (json['total_withdrawn'] as num?)?.toDouble() ?? 0,
    pendingWithdrawals: (json['pending_withdrawals'] as num?)?.toDouble() ?? 0,
    feeFreeBalance: (json['fee_free_balance'] as num?)?.toDouble() ?? 0,
  );
}

/// Nature d'un mouvement, alignée sur `WALLET_TRANSACTION_TYPES` du serveur.
enum WalletTransactionType {
  credit('credit', LucideIcons.arrowDownLeft),
  withdrawal('withdrawal', LucideIcons.arrowUpRight),
  withdrawalReversal('withdrawal_reversal', LucideIcons.undo2),
  refund('refund', LucideIcons.rotateCcw),
  subscriptionRefund('subscription_refund', LucideIcons.creditCard),

  /// Type ajouté au serveur après cette version de l'application : le
  /// mouvement reste affiché, sous un libellé générique, plutôt que de faire
  /// échouer toute la page.
  other('other', LucideIcons.arrowLeftRight);

  const WalletTransactionType(this.code, this.icon);

  final String code;
  final IconData icon;

  /// Clé de traduction du libellé.
  String get labelKey => 'wallet.movement.$code';

  static WalletTransactionType fromCode(String? code) =>
      values.firstWhere((t) => t.code == code, orElse: () => other);
}

/// Mouvement d'un portefeuille, tel que servi par
/// `GET /proprio/wallets/:id/transactions`.
class WalletTransactionModel {
  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.createdAt,
  });

  final String id;
  final WalletTransactionType type;

  /// Signé : positif au crédit, négatif au débit — le serveur pose le signe,
  /// l'écran ne le déduit pas du type.
  final double amount;
  final double balanceAfter;
  final DateTime createdAt;

  bool get isCredit => amount >= 0;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) =>
      WalletTransactionModel(
        id: json['id'] as String? ?? '',
        type: WalletTransactionType.fromCode(json['type'] as String?),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Une page de mouvements, avec de quoi savoir s'il en reste.
class WalletTransactionPage {
  const WalletTransactionPage({
    required this.items,
    required this.page,
    required this.lastPage,
  });

  final List<WalletTransactionModel> items;
  final int page;
  final int lastPage;

  bool get hasMore => page < lastPage;

  factory WalletTransactionPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List? ?? const [];
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return WalletTransactionPage(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(WalletTransactionModel.fromJson)
          .toList(growable: false),
      page: (meta['currentPage'] as num?)?.toInt() ?? 1,
      lastPage: (meta['lastPage'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Statut d'une demande de retrait.
enum WithdrawalStatus {
  pending('pending'),
  paid('paid'),
  rejected('rejected');

  const WithdrawalStatus(this.code);

  final String code;

  static WithdrawalStatus fromCode(String? code) => switch (code) {
    'paid' => WithdrawalStatus.paid,
    'rejected' => WithdrawalStatus.rejected,
    _ => WithdrawalStatus.pending,
  };
}

/// Demande de retrait d'un portefeuille.
class WithdrawalModel {
  const WithdrawalModel({
    required this.id,
    required this.walletId,
    required this.residenceName,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.payoutPhone,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.processedAt,
  });

  final String id;
  final String walletId;
  final String? residenceName;

  /// Débité du portefeuille.
  final double amount;
  final double fee;

  /// Versé au propriétaire, frais retirés.
  final double netAmount;
  final String payoutPhone;
  final WithdrawalStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? processedAt;

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) =>
      WithdrawalModel(
        id: json['id'] as String? ?? '',
        walletId: json['wallet_id'] as String? ?? '',
        residenceName: json['residence_name'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        fee: (json['fee'] as num?)?.toDouble() ?? 0,
        netAmount: (json['net_amount'] as num?)?.toDouble() ?? 0,
        payoutPhone: json['payout_phone'] as String? ?? '',
        status: WithdrawalStatus.fromCode(json['status'] as String?),
        rejectionReason: json['rejection_reason'] as String?,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        processedAt: DateTime.tryParse(json['processed_at'] as String? ?? ''),
      );
}

/// Règles de retrait, miroir de `wallet_rules.ts` côté API : l'écran annonce
/// les frais avant l'envoi, le serveur reste l'autorité.
abstract final class WithdrawalRules {
  static const feeRate = 0.01;
  static const minimum = 1000;

  /// Frais de 1 %, au franc supérieur comme au serveur. La part prise sur
  /// [feeFreeBalance] — un remboursement d'abonnement — n'en paie pas.
  static double feeFor(double amount, {double feeFreeBalance = 0}) {
    final charged = amount - feeFreeBalance.clamp(0, amount);
    return charged <= 0 ? 0 : (charged * feeRate).ceilToDouble();
  }
}
