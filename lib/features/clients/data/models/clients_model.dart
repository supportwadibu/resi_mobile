class ClientsModel {
  const ClientsModel({
    required this.id,
    // TODO: add fields
  });

  final String id;
  // TODO: add fields

  factory ClientsModel.fromJson(Map<String, dynamic> json) {
    return ClientsModel(
      id: json['id'] as String,
      // TODO: map fields
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // TODO: map fields
      };

  ClientsModel copyWith({
    String? id,
    // TODO: add fields
  }) {
    return ClientsModel(id: id ?? this.id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientsModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ClientsModel(id: $id)';
}
