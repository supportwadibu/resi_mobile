class StatsModel {
  const StatsModel({
    required this.id,
    // TODO: add fields
  });

  final String id;
  // TODO: add fields

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      id: json['id'] as String,
      // TODO: map fields
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        // TODO: map fields
      };

  StatsModel copyWith({
    String? id,
    // TODO: add fields
  }) {
    return StatsModel(id: id ?? this.id);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'StatsModel(id: $id)';
}
