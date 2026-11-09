/// Code de réinitialisation demandé, prêt pour la saisie.
class PasswordResetRequest {
  const PasswordResetRequest({
    required this.identifier,
    required this.channel,
    this.devOtpCode,
  });

  factory PasswordResetRequest.fromJson(
    String identifier,
    Map<String, dynamic> json,
  ) => PasswordResetRequest(
    identifier: identifier,
    // Repli sur le téléphone : la connexion par mot de passe est celle du
    // gérant, qui se connecte par son numéro.
    channel: json['channel'] as String? ?? 'phone',
    devOtpCode: json['dev_otp_code'] as String?,
  );

  /// Identifiant normalisé, à renvoyer tel quel avec le code.
  final String identifier;

  /// `phone` (code par WhatsApp) ou `email`.
  final String channel;

  /// Code en clair fourni par l'API hors production. Nul en production.
  final String? devOtpCode;
}
