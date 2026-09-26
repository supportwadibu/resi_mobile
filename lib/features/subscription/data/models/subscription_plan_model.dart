/// Forfait proposé à la souscription, tel que servi par `GET /proprio/plans`.
class SubscriptionPlanModel {
  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.isFull,
    this.description = '',
    this.features = const [],
  });

  final String id;
  final String name;
  final String description;

  /// Prix en francs CFA.
  final double price;
  final int durationDays;

  /// Forfait complet (5 000 F), par opposition au forfait d'enregistrement.
  final bool isFull;

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
      isFull: json['tier'] != 'basic',
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
