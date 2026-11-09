/// Avis rendu par `GET /auth/account/deletion` : un obstacle ou une perte.
///
/// [message] est rédigé par l'API, en français, et s'affiche tel quel :
/// les montants et les nombres de séjours y sont déjà formulés. [code] sert
/// à choisir l'icône, jamais le texte.
class AccountDeletionNotice {
  const AccountDeletionNotice({required this.code, required this.message});

  factory AccountDeletionNotice.fromJson(Map<String, dynamic> json) =>
      AccountDeletionNotice(
        code: json['code'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  final String code;
  final String message;
}

/// Ce que l'utilisateur doit savoir avant de supprimer son compte.
class AccountDeletionPreview {
  const AccountDeletionPreview({
    required this.canDelete,
    required this.blockers,
    required this.warnings,
    required this.gracePeriodDays,
  });

  factory AccountDeletionPreview.fromJson(Map<String, dynamic> json) {
    List<AccountDeletionNotice> notices(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .map(
              (e) => AccountDeletionNotice.fromJson(e as Map<String, dynamic>),
            )
            .toList();

    return AccountDeletionPreview(
      canDelete: json['can_delete'] as bool? ?? false,
      blockers: notices('blockers'),
      warnings: notices('warnings'),
      // Repli sur le délai annoncé par les règles de confidentialité.
      gracePeriodDays: json['grace_period_days'] as int? ?? 30,
    );
  }

  /// Faux tant qu'un obstacle subsiste : l'API refuserait la suppression.
  final bool canDelete;
  final List<AccountDeletionNotice> blockers;
  final List<AccountDeletionNotice> warnings;

  /// Jours avant l'effacement définitif, pendant lesquels le support peut
  /// encore annuler la suppression.
  final int gracePeriodDays;
}
