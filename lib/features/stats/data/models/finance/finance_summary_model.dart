class FinanceSummaryModel {
  final double caBrut;
  final double depenses;
  final double beneficeNet;
  final double tauxOccupation;
  final int reservations;
  final double moyenSejour;

  const FinanceSummaryModel({
    required this.caBrut,
    required this.depenses,
    required this.beneficeNet,
    required this.tauxOccupation,
    required this.reservations,
    required this.moyenSejour,
  });

  factory FinanceSummaryModel.fromJson(Map<String, dynamic> json) =>
      FinanceSummaryModel(
        caBrut: (json['ca_brut'] as num?)?.toDouble() ?? 0,
        depenses: (json['depenses'] as num?)?.toDouble() ?? 0,
        beneficeNet: (json['benefice_net'] as num?)?.toDouble() ?? 0,
        tauxOccupation: (json['taux_occupation'] as num?)?.toDouble() ?? 0,
        reservations: json['reservations'] as int? ?? 0,
        moyenSejour: (json['moyen_sejour'] as num?)?.toDouble() ?? 0,
      );
}
