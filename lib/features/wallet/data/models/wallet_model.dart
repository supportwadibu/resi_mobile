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

  factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
    id: json['id'] as String? ?? '',
    residenceId: json['residence_id'] as String?,
    residenceName: json['residence_name'] as String?,
    balance: (json['balance'] as num?)?.toDouble() ?? 0,
    totalCredited: (json['total_credited'] as num?)?.toDouble() ?? 0,
    totalWithdrawn: (json['total_withdrawn'] as num?)?.toDouble() ?? 0,
    pendingWithdrawals: (json['pending_withdrawals'] as num?)?.toDouble() ?? 0,
  );
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

  /// Frais de 1 %, au franc supérieur comme au serveur.
  static double feeFor(double amount) =>
      amount <= 0 ? 0 : (amount * feeRate).ceilToDouble();
}
