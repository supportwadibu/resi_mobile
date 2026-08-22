/// Réponse de `POST /auth/register/init`.
///
/// Cette étape ne connecte pas l'utilisateur : elle crée un compte non vérifié
/// et envoie un code à usage unique. Les tokens ne sont délivrés qu'après
/// `POST /auth/register/verify`.
class RegisterInitModel {
  const RegisterInitModel({
    required this.userId,
    required this.target,
    this.devOtpCode,
  });

  final String userId;

  /// Destination du code — l'e-mail ou le numéro saisi. Sert à l'afficher sur
  /// l'écran de saisie ("Code envoyé à ...").
  final String target;

  /// Code en clair, renvoyé par l'API **hors production uniquement** pour
  /// faciliter les essais sans accès à la boîte mail ou aux SMS.
  final String? devOtpCode;

  factory RegisterInitModel.fromJson(Map<String, dynamic> json) {
    return RegisterInitModel(
      userId: json['user_id'] as String,
      target: json['target'] as String? ?? '',
      devOtpCode: json['dev_otp_code'] as String?,
    );
  }
}
