/// Utilisateur authentifié, tel que renvoyé par l'API dans la clé `user`.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.role,
    required this.isVerified,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String role;
  final bool isVerified;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  bool get isOwner => role == 'proprio';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'client',
      isVerified: json['is_verified'] as bool? ?? false,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'role': role,
    'is_verified': isVerified,
    'email': email,
    'phone': phone,
    'avatar_url': avatarUrl,
  };
}

/// Réponse d'authentification de l'API : paire de tokens + profil utilisateur.
class AuthModel {
  const AuthModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.isNewUser = false,
  });

  final AuthUser user;
  final String accessToken;
  final String refreshToken;

  /// Vrai lorsque le compte vient d'être créé lors de ce login (flux Google).
  final bool isNewUser;

  String get id => user.id;
  String get name => user.fullName;
  String? get email => user.email;

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      isNewUser: json['is_new_user'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'is_new_user': isNewUser,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthModel &&
          runtimeType == other.runtimeType &&
          user.id == other.user.id;

  @override
  int get hashCode => user.id.hashCode;

  @override
  String toString() => 'AuthModel(id: ${user.id}, role: ${user.role})';
}
