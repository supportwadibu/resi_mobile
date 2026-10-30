/// Usage des gains, aligné sur `REDEMPTION_TYPES` du serveur.
enum RedemptionType {
  withdrawal('withdrawal'),
  stayCredit('stay_credit'),
  subscriptionCredit('subscription_credit'),

  /// Usage ajouté au serveur après cette version : affiché sous un libellé
  /// générique, jamais proposé.
  other('other');

  const RedemptionType(this.code);

  final String code;

  String get labelKey => 'sponsorship.redemption_type.$code';

  static RedemptionType fromCode(String? code) =>
      values.firstWhere((t) => t.code == code, orElse: () => other);
}

/// Étape d'un filleul, alignée sur `SPONSORSHIP_STATUSES` du serveur.
enum SponsoredStatus {
  /// Inscrit, pas encore d'action qui rapporte.
  registered('registered'),

  /// Gain acquis, dans son délai d'attente.
  pending('pending'),

  /// Gain disponible.
  earned('earned'),
  cancelled('cancelled');

  const SponsoredStatus(this.code);

  final String code;

  String get labelKey => 'sponsorship.status.$code';

  static SponsoredStatus fromCode(String? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => registered);
}

/// Gain promis par filleul, selon son rôle.
class RewardView {
  const RewardView({
    required this.isPercent,
    required this.value,
    this.maxAmount,
  });

  final bool isPercent;
  final num value;

  /// Plafond d'un gain en pourcentage ; `null` : sans plafond.
  final num? maxAmount;

  factory RewardView.fromJson(Map<String, dynamic>? json) => RewardView(
    isPercent: json?['mode'] == 'percent',
    value: (json?['value'] as num?) ?? 0,
    maxAmount: json?['max_amount'] as num?,
  );
}

/// Écran Parrainage, tel que servi par `GET /sponsorship`.
class SponsorshipOverview {
  const SponsorshipOverview({
    required this.code,
    required this.balance,
    required this.pendingBalance,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.sponsoredCount,
    required this.rewardedCount,
    required this.sponsorName,
    required this.canApplyCode,
    required this.enabled,
    required this.ownerReward,
    required this.clientReward,
    required this.minimumAmount,
    required this.options,
  });

  /// Code à partager.
  final String code;

  /// Gains disponibles. Négatif après l'annulation d'un gain déjà dépensé.
  final double balance;

  /// Gains acquis, encore dans leur délai d'attente.
  final double pendingBalance;
  final double totalEarned;
  final double totalRedeemed;
  final int sponsoredCount;
  final int rewardedCount;

  /// Nom de son propre parrain, s'il en a un.
  final String? sponsorName;

  /// Peut-il encore saisir le code d'un parrain ?
  final bool canApplyCode;

  /// Gains activés par l'équipe RESI.
  final bool enabled;

  /// Gain par filleul propriétaire (abonnement payé) et client (séjour payé).
  final RewardView ownerReward;
  final RewardView clientReward;

  /// Seuil d'une demande, et usages ouverts au compte.
  final int minimumAmount;
  final List<RedemptionType> options;

  bool get canRedeem => balance >= minimumAmount && options.isNotEmpty;

  /// Progression vers le seuil, entre 0 et 1.
  double get progress =>
      minimumAmount <= 0 ? 1 : (balance / minimumAmount).clamp(0, 1).toDouble();

  factory SponsorshipOverview.fromJson(Map<String, dynamic> json) {
    final account = json['account'] as Map<String, dynamic>? ?? const {};
    final program = json['program'] as Map<String, dynamic>? ?? const {};
    final rewards = program['rewards'] as Map<String, dynamic>? ?? const {};
    final redemption =
        program['redemption'] as Map<String, dynamic>? ?? const {};

    return SponsorshipOverview(
      code: account['code'] as String? ?? '',
      balance: (account['balance'] as num?)?.toDouble() ?? 0,
      pendingBalance: (account['pending_balance'] as num?)?.toDouble() ?? 0,
      totalEarned: (account['total_earned'] as num?)?.toDouble() ?? 0,
      totalRedeemed: (account['total_redeemed'] as num?)?.toDouble() ?? 0,
      sponsoredCount: (json['sponsored_count'] as num?)?.toInt() ?? 0,
      rewardedCount: (json['rewarded_count'] as num?)?.toInt() ?? 0,
      sponsorName:
          (json['sponsor'] as Map<String, dynamic>?)?['full_name'] as String?,
      canApplyCode: json['can_apply_code'] as bool? ?? false,
      enabled: program['enabled'] as bool? ?? false,
      ownerReward: RewardView.fromJson(
        rewards['proprio'] as Map<String, dynamic>?,
      ),
      clientReward: RewardView.fromJson(
        rewards['client'] as Map<String, dynamic>?,
      ),
      minimumAmount: (redemption['minimum_amount'] as num?)?.toInt() ?? 0,
      options: ((redemption['options'] as List?) ?? const [])
          .map((o) => RedemptionType.fromCode(o as String?))
          .where((o) => o != RedemptionType.other)
          .toList(growable: false),
    );
  }
}

/// Un filleul, tel que servi par `GET /sponsorship/sponsored`.
class SponsoredUser {
  const SponsoredUser({
    required this.id,
    required this.fullName,
    required this.isOwner,
    required this.status,
    required this.rewardAmount,
    required this.createdAt,
    this.availableAt,
  });

  final String id;

  /// Nom figé à l'inscription.
  final String fullName;
  final bool isOwner;
  final SponsoredStatus status;
  final double rewardAmount;
  final DateTime createdAt;

  /// Date de disponibilité d'un gain en attente.
  final DateTime? availableAt;

  factory SponsoredUser.fromJson(Map<String, dynamic> json) => SponsoredUser(
    id: json['id'] as String? ?? '',
    fullName: json['full_name'] as String? ?? '',
    isOwner: json['role'] == 'proprio',
    status: SponsoredStatus.fromCode(json['status'] as String?),
    rewardAmount: (json['reward_amount'] as num?)?.toDouble() ?? 0,
    createdAt:
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
    availableAt: DateTime.tryParse(json['available_at'] as String? ?? ''),
  );
}

/// Statut d'une demande, aligné sur `REDEMPTION_STATUSES` du serveur.
enum RedemptionStatus {
  pending('pending'),
  paid('paid'),
  rejected('rejected'),

  /// Conversion appliquée sur-le-champ.
  completed('completed');

  const RedemptionStatus(this.code);

  final String code;

  static RedemptionStatus fromCode(String? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => pending);
}

/// Retrait ou conversion des gains, tel que servi par
/// `GET /sponsorship/redemptions`.
class RedemptionModel {
  const RedemptionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.payoutPhone,
    this.rejectionReason,
  });

  final String id;
  final RedemptionType type;
  final double amount;
  final RedemptionStatus status;
  final DateTime createdAt;
  final String? payoutPhone;
  final String? rejectionReason;

  factory RedemptionModel.fromJson(Map<String, dynamic> json) =>
      RedemptionModel(
        id: json['id'] as String? ?? '',
        type: RedemptionType.fromCode(json['type'] as String?),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        status: RedemptionStatus.fromCode(json['status'] as String?),
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        payoutPhone: json['payout_phone'] as String?,
        rejectionReason: json['rejection_reason'] as String?,
      );
}

/// Résultat de `GET /sponsorship/codes/:code`.
class SponsorshipCodeCheck {
  const SponsorshipCodeCheck({
    required this.code,
    required this.sponsorFirstName,
  });

  /// Code sous sa forme canonique.
  final String code;
  final String sponsorFirstName;

  factory SponsorshipCodeCheck.fromJson(Map<String, dynamic> json) =>
      SponsorshipCodeCheck(
        code: json['code'] as String? ?? '',
        sponsorFirstName: json['sponsor_first_name'] as String? ?? '',
      );
}
