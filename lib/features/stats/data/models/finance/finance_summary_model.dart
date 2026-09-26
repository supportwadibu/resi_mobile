class FinanceSummaryModel {
  final double caBrut;
  final double depenses;
  final double beneficeNet;
  final double tauxOccupation;
  final int reservations;
  final double moyenSejour;

  /// Sommes rendues sur départs anticipés, déjà déduites de [caBrut] par le
  /// serveur : à afficher, jamais à retrancher une seconde fois.
  final double remboursements;

  /// Commissions dues aux apporteurs d'affaire, déjà retranchées de
  /// [beneficeNet] par le serveur.
  final double commissions;

  const FinanceSummaryModel({
    this.remboursements = 0,
    this.commissions = 0,
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
        // Absent des réponses d'un serveur antérieur au départ anticipé.
        remboursements: (json['remboursements'] as num?)?.toDouble() ?? 0,
        // Absent des réponses d'un serveur antérieur aux apporteurs.
        commissions: (json['commissions'] as num?)?.toDouble() ?? 0,
      );
}
