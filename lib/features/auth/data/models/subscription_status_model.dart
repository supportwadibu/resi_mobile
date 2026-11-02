/// État d'abonnement du propriétaire, tel que renvoyé par
/// `GET /api/v1/proprio/subscription`.
///
/// Le serveur pré-calcule les jours restants et les drapeaux d'accès : le
/// client n'a aucune règle métier à rejouer, et l'affichage ne peut pas
/// diverger de la décision du backend.
class SubscriptionStatusModel {
  const SubscriptionStatusModel({
    required this.isTrial,
    required this.daysRemaining,
    required this.canOperate,
    required this.awaitingValidation,
    required this.profileSubmitted,
    this.ownerStatus,
    this.status,
    this.endDate,
    this.planAccess,
  });

  /// L'abonnement en cours est un essai gratuit.
  final bool isTrial;

  /// Jours pleins restants avant l'échéance, arrondis au supérieur. Zéro
  /// lorsque l'essai est terminé ou qu'aucun abonnement n'existe.
  final int daysRemaining;

  /// Le propriétaire peut exploiter ses annonces.
  final bool canOperate;

  /// Dossier déposé, en attente de décision d'un administrateur.
  final bool awaitingValidation;

  /// Les pièces d'identité ont-elles été transmises ?
  ///
  /// À ne pas confondre avec [awaitingValidation] : un compte est `pending` dès
  /// sa création, bien avant que son titulaire ait déposé quoi que ce soit.
  /// C'est ce drapeau qui décide du rappel de finalisation.
  final bool profileSubmitted;

  /// `pending`, `active`, `rejected` ou `suspended`.
  final String? ownerStatus;

  /// Statut de l'abonnement : `trial`, `active`, `expired`…
  final String? status;

  final DateTime? endDate;

  /// Palier ouvert : `free`, `pro`, `pro_plus` — ou `basic` / `full` d'un
  /// serveur antérieur —, `null` pour un compte inactif. Absent d'un serveur
  /// antérieur aux forfaits, qui ne bloquait rien : le repli est alors
  /// l'accès complet. Lu par `PlanAccess.fromApi`.
  final String? planAccess;

  /// Le compte a été suspendu faute de validation dans les temps.
  bool get isSuspended => ownerStatus == 'suspended';

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    // L'abonnement est nul tant qu'aucun essai n'a été ouvert : les champs qui
    // en dépendent restent alors absents, sans que ce soit une erreur.
    final subscription = json['subscription'] as Map<String, dynamic>?;
    final endDate = subscription?['end_date'] as String?;

    return SubscriptionStatusModel(
      isTrial: json['is_trial'] as bool? ?? false,
      daysRemaining: json['days_remaining'] as int? ?? 0,
      canOperate: json['can_operate'] as bool? ?? false,
      awaitingValidation: json['awaiting_validation'] as bool? ?? false,
      profileSubmitted: json['profile_submitted'] as bool? ?? false,
      ownerStatus: json['owner_status'] as String?,
      status: subscription?['status'] as String?,
      endDate: endDate == null ? null : DateTime.tryParse(endDate),
      // `plan_tier` porte les paliers actuels (`free`, `pro`, `pro_plus`) ;
      // `plan_access` les garde dans l'ancien vocabulaire pour les versions
      // déjà installées, et sert de repli face à un serveur antérieur.
      planAccess: json.containsKey('plan_tier')
          ? json['plan_tier'] as String?
          : json.containsKey('plan_access')
          ? json['plan_access'] as String?
          : 'full',
    );
  }
}
