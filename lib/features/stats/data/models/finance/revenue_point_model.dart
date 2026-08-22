class RevenuePointModel {
  final String month;
  final double value;

  const RevenuePointModel({required this.month, required this.value});

  factory RevenuePointModel.fromJson(Map<String, dynamic> json) =>
      RevenuePointModel(
        month: json['month'] as String? ?? '',
        value: (json['value'] as num?)?.toDouble() ?? 0,
      );
}
