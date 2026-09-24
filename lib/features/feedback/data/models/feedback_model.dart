/// Nature d'un avis, telle que l'API l'accepte.
///
/// Les valeurs sérialisées sont figées par le contrat : les renommer
/// invaliderait les avis déjà enregistrés côté back-office.
enum FeedbackType {
  suggestion('suggestion'),
  bug('bug'),
  amelioration('amelioration'),
  autre('autre');

  const FeedbackType(this.value);

  final String value;

  static FeedbackType fromValue(String? value) {
    return FeedbackType.values.firstWhere(
      (type) => type.value == value,
      // Un type inconnu vient d'une version d'API plus récente : le ranger dans
      // « autre » vaut mieux que faire échouer l'affichage de l'historique.
      orElse: () => FeedbackType.autre,
    );
  }
}

/// Avancement du traitement par l'équipe RESI.
enum FeedbackStatus {
  newFeedback('new'),
  read('read'),
  inProgress('in_progress'),
  closed('closed');

  const FeedbackStatus(this.value);

  final String value;

  static FeedbackStatus fromValue(String? value) {
    return FeedbackStatus.values.firstWhere(
      (status) => status.value == value,
      // `status` est arrivé avec le back-office : les tout premiers avis n'en
      // portent pas et se présentent comme non traités.
      orElse: () => FeedbackStatus.newFeedback,
    );
  }
}

/// Contexte technique joint à l'envoi.
///
/// Collecté par l'application, jamais saisi ni montré : un « le calendrier
/// reste vide » sans version ni système est presque inexploitable pour
/// l'équipe qui devra reproduire.
class FeedbackContext {
  const FeedbackContext({
    this.appVersion,
    this.flavor,
    this.platform,
    this.osVersion,
    this.deviceModel,
  });

  final String? appVersion;
  final String? flavor;
  final String? platform;
  final String? osVersion;
  final String? deviceModel;

  /// Seuls les champs connus sont envoyés : l'API les accepte tous absents.
  Map<String, dynamic> toJson() => {
    if (appVersion != null) 'app_version': appVersion,
    if (flavor != null) 'flavor': flavor,
    if (platform != null) 'platform': platform,
    if (osVersion != null) 'os_version': osVersion,
    if (deviceModel != null) 'device_model': deviceModel,
  };
}

/// Avis enregistré, tel que l'API le renvoie à son auteur.
class FeedbackModel {
  const FeedbackModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final FeedbackType type;
  final String title;
  final String message;
  final FeedbackStatus status;
  final DateTime createdAt;

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as String? ?? '',
      type: FeedbackType.fromValue(json['type'] as String?),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      status: FeedbackStatus.fromValue(json['status'] as String?),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Ce qui part vers l'API à la validation du formulaire.
class CreateFeedbackPayload {
  const CreateFeedbackPayload({
    required this.type,
    required this.title,
    required this.message,
    required this.context,
  });

  final FeedbackType type;
  final String title;
  final String message;
  final FeedbackContext context;

  Map<String, dynamic> toJson() => {
    'type': type.value,
    'title': title,
    'message': message,
    'context': context.toJson(),
  };
}
