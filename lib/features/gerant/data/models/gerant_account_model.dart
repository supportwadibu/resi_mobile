/// Compte gérant vu par le propriétaire qui l'a ouvert.
///
/// À ne pas confondre avec `PropertyManagerModel` de la feature `auth`, qui
/// décrit le dossier de validation du **propriétaire** lui-même malgré son nom.
/// Ici il s'agit d'un utilisateur distinct, à qui le propriétaire confie une
/// partie de son parc.
///
/// Le mot de passe n'y figure jamais : le propriétaire le fixe à la création et
/// ne peut plus le relire, le serveur ne rendant pas même son empreinte.
class GerantAccountModel {
  const GerantAccountModel({
    required this.id,
    required this.fullName,
    required this.isActive,
    this.email,
    this.phone,
    this.propertyIds = const [],
    this.createdAt,
  });

  final String id;
  final String fullName;

  /// Au moins l'un des deux est renseigné : c'est par là que le gérant se
  /// connecte, et le serveur refuse un compte qui n'en porterait aucun.
  final String? email;
  final String? phone;

  /// Croise l'état du compte et celui de l'affectation côté serveur : suspendre
  /// l'un ou l'autre suffit à couper l'accès, et l'application n'a donc qu'un
  /// seul état à présenter.
  final bool isActive;

  /// Périmètre confié, toujours en identifiants de **logements**. Le serveur
  /// ignore les résidences : y regrouper l'affichage relève de l'interface.
  final List<String> propertyIds;

  final DateTime? createdAt;

  int get propertiesCount => propertyIds.length;

  /// Coordonnée montrée en liste. L'e-mail prime quand les deux existent : il
  /// est plus discriminant qu'un numéro à l'écran.
  String? get contact => email ?? phone;

  factory GerantAccountModel.fromJson(Map<String, dynamic> json) {
    return GerantAccountModel(
      // Le serveur expose la clé du document sous `_id`. `id` est lu en repli
      // pour les rares points d'entrée qui normalisent déjà la clé.
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      email: _trimmedOrNull(json['email']),
      phone: _trimmedOrNull(json['phone']),
      propertyIds:
          (json['property_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  static String? _trimmedOrNull(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Charge utile de création d'un gérant : compte et périmètre en une requête.
class CreateGerantPayload {
  const CreateGerantPayload({
    required this.fullName,
    required this.password,
    this.email,
    this.phone,
    this.propertyIds = const [],
  });

  final String fullName;

  /// Mot de passe initial, d'au moins 8 caractères. Le gérant le changera
  /// depuis son profil ; le propriétaire doit donc le lui communiquer.
  final String password;

  final String? email;
  final String? phone;
  final List<String> propertyIds;

  Map<String, dynamic> toJson() => {
    'full_name': fullName.trim(),
    'password': password,
    // Une coordonnée vide n'est pas envoyée plutôt qu'envoyée vide : le
    // validateur la refuserait comme adresse malformée au lieu de constater
    // son absence, et le message affiché parlerait du mauvais problème.
    if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
    if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
    // Toujours présent, même vide : le serveur attend la clé, et un gérant
    // ouvert sans logement est un cas légitime.
    'property_ids': propertyIds,
  };
}

/// Renommage et coordonnées. Le mot de passe n'en fait pas partie : il relève
/// du profil du gérant, que lui seul modifie.
class UpdateGerantPayload {
  const UpdateGerantPayload({this.fullName, this.email, this.phone});

  final String? fullName;
  final String? email;
  final String? phone;

  Map<String, dynamic> toJson() => {
    if (fullName != null && fullName!.trim().isNotEmpty)
      'full_name': fullName!.trim(),
    if (email != null) 'email': email!.trim().isEmpty ? null : email!.trim(),
    if (phone != null) 'phone': phone!.trim().isEmpty ? null : phone!.trim(),
  };

  bool get isEmpty => toJson().isEmpty;
}
