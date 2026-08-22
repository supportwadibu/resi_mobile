class RapportModel {
  const RapportModel({
    required this.id,
    // TODO: add fields
  });

  final String id;
  // TODO: add fields

  factory RapportModel.fromJson(Map<String, dynamic> json) {
    return RapportModel(
      id: json['id'] as String,
      // TODO: map fields
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // TODO: map fields
      };

  RapportModel copyWith({
    String? id,
    // TODO: add fields
  }) {
    return RapportModel(id: id ?? this.id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RapportModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'RapportModel(id: $id)';
}
