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
  });

  /// Le renouvellement est ouvert : 7 jours avant l'échéance, ou aucun forfait
  /// payant en cours.
  final bool renewable;

  /// Un forfait payant est en cours : il peut être résilié.
  final bool cancellable;

  /// Rendu au portefeuille RESI en cas de résiliation maintenant.
  final double refundAmount;

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
    return SubscriptionOptionsModel(
      renewable: json['renewable'] as bool? ?? true,
      cancellable: json['cancellable'] as bool? ?? false,
      refundAmount: (json['refund_amount'] as num?)?.toDouble() ?? 0,
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
