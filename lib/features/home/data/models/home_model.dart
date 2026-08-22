class HomeModel {
  const HomeModel({
    required this.id,
    // TODO: add fields
  });

  final String id;
  // TODO: add fields

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    return HomeModel(
      id: json['id'] as String,
      // TODO: map fields
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // TODO: map fields
      };

  HomeModel copyWith({
    String? id,
    // TODO: add fields
  }) {
    return HomeModel(id: id ?? this.id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'HomeModel(id: $id)';
}
