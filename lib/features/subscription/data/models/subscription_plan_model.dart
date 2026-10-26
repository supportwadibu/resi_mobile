import 'plan_access.dart';

/// Forfait proposé à la souscription, tel que servi par `GET /proprio/plans`.
class SubscriptionPlanModel {
  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.access,
    this.description = '',
    this.features = const [],
  });

  final String id;
  final String name;
  final String description;

  /// Prix en francs CFA.
  final double price;
  final int durationDays;

  /// Palier que le forfait ouvre : RESI Pro ou RESI Pro+.
  final PlanAccess access;

  /// Lignes de présentation saisies par l'administrateur.
  final List<String> features;

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 30,
      // Un plan sans palier est lu complet par le serveur : même repli ici,
      // pour que l'écran n'annonce pas moins que ce que le plan ouvre.
      access: PlanAccess.fromApi(json['tier'] as String? ?? 'pro_plus'),
      features: (json['features'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
    );
  }
}

/// Paiement Wave lancé pour un forfait.
class SubscriptionCheckoutModel {
  const SubscriptionCheckoutModel({
    required this.reference,
    required this.paymentUrl,
  });

  /// Référence du paiement côté RESI, à rappeler pour la confirmation.
  final String reference;

  /// Lien Wave : il ouvre l'application Wave sur le téléphone.
  final String paymentUrl;

  factory SubscriptionCheckoutModel.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>? ?? const {};
    return SubscriptionCheckoutModel(
      reference: payment['reference'] as String? ?? '',
      paymentUrl: json['payment_url'] as String? ?? '',
    );
  }
}

/// Issue d'un paiement, telle que constatée par le serveur chez Wave.
enum SubscriptionPaymentStatus {
  pending,
  success,
  failed,
  expired;

  static SubscriptionPaymentStatus fromCode(String? code) => switch (code) {
    'success' => SubscriptionPaymentStatus.success,
    'failed' || 'refunded' => SubscriptionPaymentStatus.failed,
    'expired' => SubscriptionPaymentStatus.expired,
    _ => SubscriptionPaymentStatus.pending,
  };
}

/// Issue d'une résiliation, selon `cancellation_policy.ts` côté API.
enum CancelMode {
  /// 7 premiers jours : tout est rendu, l'accès s'arrête aussitôt.
  fullRefund('full_refund'),

  /// Pro+ en deuxième semaine : une part rendue, une part en crédit.
  partialRefund('partial_refund'),

  /// Rien n'est rendu : l'abonnement court jusqu'à l'échéance.
  periodEnd('period_end');

  const CancelMode(this.code);

  final String code;

  static CancelMode? fromCode(String? code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    return null;
  }
}

/// Crédit d'abonnement bloqué : déduit du prochain paiement, non retirable.
class SubscriptionCredit {
  const SubscriptionCredit({required this.amount, required this.expiresAt});

  final double amount;
  final DateTime? expiresAt;

  factory SubscriptionCredit.fromJson(Map<String, dynamic> json) =>
      SubscriptionCredit(
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      );
}

/// Détail d'un paiement d'abonnement, annoncé avant d'ouvrir Wave.
class CheckoutQuote {
  const CheckoutQuote({
    required this.price,
    required this.credit,
    required this.amount,
    required this.fee,
  });

  /// Prix du forfait, ou d'une montée au prorata.
  final double price;

  /// Crédit d'abonnement déduit.
  final double credit;

  /// Prix après crédit, sans les frais.
  final double amount;

  /// Frais Wave.
  final double fee;

  /// Débité par Wave.
  double get total => amount + fee;
}

/// Ce que le propriétaire peut faire de son forfait en cours, chiffré par
/// `GET /proprio/subscription/options`.
///
/// Les montants viennent du serveur : le remboursement annoncé avant de
/// résilier est celui qui sera crédité, et le prix d'une montée celui que
/// Wave encaissera.
class SubscriptionOptionsModel {
  const SubscriptionOptionsModel({
    required this.renewable,
    required this.cancellable,
    required this.refundAmount,
    required this.remainingDays,
    this.upgrades = const {},
    this.cancelMode,
    this.refundCredit = 0,
    this.accessEndsAt,
    this.cancelScheduled = false,
    this.credit,
    this.waveFeeRate = defaultWaveFeeRate,
  });

  /// Frais Wave d'un serveur antérieur à leur annonce : ceux que Wave
  /// prélève, pour que la fenêtre de paiement ne les taise pas.
  static const defaultWaveFeeRate = 0.01;

  /// Le renouvellement est ouvert : 7 jours avant l'échéance, ou aucun forfait
  /// payant en cours.
  final bool renewable;

  /// Un forfait payant est en cours et pas encore résilié.
  final bool cancellable;

  /// Issue d'une résiliation maintenant ; `null` sans forfait résiliable.
  final CancelMode? cancelMode;

  /// Rendu au portefeuille RESI en cas de résiliation maintenant.
  final double refundAmount;

  /// Gardé en crédit d'abonnement en cas de résiliation maintenant.
  final double refundCredit;

  /// Fin de l'accès en cas de résiliation maintenant.
  final DateTime? accessEndsAt;

  /// Déjà résilié sans remboursement : actif jusqu'à l'échéance.
  final bool cancelScheduled;

  /// Crédit d'abonnement déduit du prochain paiement ; `null` sans crédit.
  final SubscriptionCredit? credit;

  /// Frais Wave ajoutés au prix d'un paiement d'abonnement.
  final double waveFeeRate;

  /// Un forfait payant court, résilié à l'échéance ou non.
  bool get hasPaidPlan => cancellable || cancelScheduled;

  /// Ce que Wave encaissera pour ce forfait, miroir de
  /// `StartSubscriptionCheckoutUseCase` : le serveur reste l'autorité.
  ///
  /// Le crédit ne ramène jamais le prix à zéro — Wave n'encaisse pas de
  /// montant nul —, et les frais, au franc supérieur, portent sur ce qui est
  /// réellement payé.
  CheckoutQuote quoteFor({required String planId, required double price}) {
    final base = upgrades[planId] ?? price;
    final available = credit?.amount ?? 0;
    final applied = base <= 1 ? 0.0 : available.clamp(0, base - 1).toDouble();
    final amount = base - applied;
    final fee = amount <= 0 ? 0.0 : (amount * waveFeeRate).ceilToDouble();
    return CheckoutQuote(
      price: base,
      credit: applied,
      amount: amount,
      fee: fee,
    );
  }

  /// Jours payés restants, sans le jour en cours.
  final int remainingDays;

  /// Prix d'une montée, par identifiant de forfait : le nouveau forfait moins
  /// la valeur des jours restants. Un forfait absent n'est pas une montée.
  final Map<String, double> upgrades;

  /// Repli d'un serveur antérieur aux options, ou d'une lecture échouée :
  /// l'écran garde son comportement d'avant — payer, sans résilier.
  static const none = SubscriptionOptionsModel(
    renewable: true,
    cancellable: false,
    refundAmount: 0,
    remainingDays: 0,
  );

  factory SubscriptionOptionsModel.fromJson(Map<String, dynamic> json) {
    final credit = json['credit'];
    return SubscriptionOptionsModel(
      renewable: json['renewable'] as bool? ?? true,
      cancellable: json['cancellable'] as bool? ?? false,
      cancelMode: CancelMode.fromCode(json['cancel_mode'] as String?),
      refundAmount: (json['refund_amount'] as num?)?.toDouble() ?? 0,
      refundCredit: (json['refund_credit'] as num?)?.toDouble() ?? 0,
      accessEndsAt: DateTime.tryParse(json['access_ends_at'] as String? ?? ''),
      cancelScheduled: json['cancel_scheduled'] as bool? ?? false,
      credit: credit is Map<String, dynamic>
          ? SubscriptionCredit.fromJson(credit)
          : null,
      waveFeeRate:
          (json['wave_fee_rate'] as num?)?.toDouble() ?? defaultWaveFeeRate,
      remainingDays: (json['remaining_days'] as num?)?.toInt() ?? 0,
      upgrades: {
        for (final upgrade
            in (json['upgrades'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>())
          upgrade['plan_id'] as String? ?? '':
              (upgrade['amount'] as num?)?.toDouble() ?? 0,
      }..remove(''),
    );
  }
}
