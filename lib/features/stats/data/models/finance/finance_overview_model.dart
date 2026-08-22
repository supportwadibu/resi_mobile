import 'finance_summary_model.dart';
import 'revenue_point_model.dart';

/// Vue financière servie par `/proprio/finance/overview`.
class FinanceOverviewModel {
  const FinanceOverviewModel({
    required this.summary,
    this.revenuePoints = const [],
  });

  final FinanceSummaryModel summary;
  final List<RevenuePointModel> revenuePoints;

  factory FinanceOverviewModel.fromJson(Map<String, dynamic> json) {
    return FinanceOverviewModel(
      summary: FinanceSummaryModel.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      revenuePoints:
          (json['revenue_points'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(RevenuePointModel.fromJson)
              .toList() ??
          const [],
    );
  }

  static const empty = FinanceOverviewModel(
    summary: FinanceSummaryModel(
      caBrut: 0,
      depenses: 0,
      beneficeNet: 0,
      tauxOccupation: 0,
      reservations: 0,
      moyenSejour: 0,
    ),
  );
}
