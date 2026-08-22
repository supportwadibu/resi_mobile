class PropertyManagerModel {
  const PropertyManagerModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phoneNumber,
    this.photoUrl,
    this.idCardType,
    this.idCardNumber,
    this.idCardFrontPath,
    this.idCardBackPath,
    this.address,
    this.city,
    this.country,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String name;
  final String phoneNumber;
  final String? photoUrl;
  final String? idCardType; // CNI, Passeport, Permis de conduire
  final String? idCardNumber;
  final String? idCardFrontPath;
  final String? idCardBackPath;
  final String? address;
  final String? city;
  final String? country;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PropertyManagerModel.fromJson(Map<String, dynamic> json) {
    return PropertyManagerModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      photoUrl: json['photo_url'] as String?,
      idCardType: json['id_card_type'] as String?,
      idCardNumber: json['id_card_number'] as String?,
      idCardFrontPath: json['id_card_front_path'] as String?,
      idCardBackPath: json['id_card_back_path'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'phone_number': phoneNumber,
        'photo_url': photoUrl,
        'id_card_type': idCardType,
        'id_card_number': idCardNumber,
        'id_card_front_path': idCardFrontPath,
        'id_card_back_path': idCardBackPath,
        'address': address,
        'city': city,
        'country': country,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  PropertyManagerModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? photoUrl,
    String? idCardType,
    String? idCardNumber,
    String? idCardFrontPath,
    String? idCardBackPath,
    String? address,
    String? city,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyManagerModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      idCardType: idCardType ?? this.idCardType,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      idCardFrontPath: idCardFrontPath ?? this.idCardFrontPath,
      idCardBackPath: idCardBackPath ?? this.idCardBackPath,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyManagerModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PropertyManagerModel(id: $id, name: $name, email: $email)';
}
