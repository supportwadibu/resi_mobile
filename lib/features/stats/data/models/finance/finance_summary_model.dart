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

  /// Part de [depenses] due aux apporteurs d'affaire : un détail, déjà compté
  /// dans [depenses] et dans [beneficeNet], jamais à retrancher.
  final double commissions;

  /// Logements ayant porté au moins un séjour sur les jours écoulés de la
  /// période, et ceux du parc qui n'en ont porté aucun.
  ///
  /// Nuls quand le serveur ne les sert pas encore : la note qu'ils
  /// alimentent disparaît alors, plutôt que d'afficher deux zéros qui se
  /// liraient comme un parc vide.
  final int? unitesLouees;
  final int? unitesLibres;

  const FinanceSummaryModel({
    this.remboursements = 0,
    this.commissions = 0,
    this.unitesLouees,
    this.unitesLibres,
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
        unitesLouees: (json['unites_louees'] as num?)?.toInt(),
        unitesLibres: (json['unites_libres'] as num?)?.toInt(),
      );
}
