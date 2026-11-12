/// Réglage de l'acompte par RESI, lu par le formulaire d'un logement.
class DepositSettings {
  const DepositSettings({
    required this.enabled,
    required this.ownerCanSet,
    required this.type,
    required this.value,
  });

  factory DepositSettings.fromJson(Map<String, dynamic> json) =>
      DepositSettings(
        enabled: json['enabled'] == true,
        ownerCanSet: json['owner_can_set'] == true,
        type: DepositType.fromCode(json['type'] as String?),
        value: (json['value'] as num?)?.toDouble() ?? 0,
      );

  /// Acompte proposé aux clients de la plateforme.
  final bool enabled;

  /// Le propriétaire règle l'acompte de chacun de ses logements.
  final bool ownerCanSet;

  /// Règle de RESI : imposée, ou repli d'un logement jamais réglé.
  final DepositType type;
  final double value;

  /// Le formulaire d'un logement n'a à montrer l'acompte que dans ce cas.
  bool get editableByOwner => enabled && ownerCanSet;
}

/// `percent` : pourcentage du séjour. `fixed` : montant en francs.
enum DepositType {
  percent('percent'),
  fixed('fixed');

  const DepositType(this.code);

  final String code;

  static DepositType fromCode(String? code) =>
      code == 'fixed' ? DepositType.fixed : DepositType.percent;
}

/// Acompte d'un logement, réglé par son propriétaire.
class PropertyDeposit {
  const PropertyDeposit({
    required this.enabled,
    required this.type,
    required this.value,
  });

  /// `null` : jamais réglé, la règle de RESI s'applique.
  static PropertyDeposit? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return PropertyDeposit(
      enabled: json['enabled'] == true,
      type: DepositType.fromCode(json['type'] as String?),
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Refusé : ce logement n'accepte que le paiement total.
  final bool enabled;
  final DepositType type;
  final double value;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'type': type.code,
    'value': value,
  };
}
