/// Chiffrage d'un départ anticipé, calculé par le serveur.
///
/// Le mobile n'en refait pas le calcul : il l'affiche, et le propriétaire ne
/// retouche que le montant retenu. Recalculer ici ferait diverger l'écran de
/// ce que la clôture enregistrera.
class EarlyCheckOutQuote {
  const EarlyCheckOutQuote({
    required this.actualCheckOutAt,
    required this.plannedCheckOutAt,
    required this.plannedDays,
    required this.billedDays,
    required this.paidAmount,
    required this.proposedAmount,
    required this.refundAmount,
  });

  final DateTime actualCheckOutAt;
  final DateTime plannedCheckOutAt;
  final int plannedDays;
  final int billedDays;

  /// Montant réglé : plafond du montant retenu.
  final double paidAmount;

  /// Prorata proposé, retouchable par le propriétaire.
  final double proposedAmount;
  final double refundAmount;

  /// Remboursement qu'entraînerait [finalAmount], jamais négatif.
  double refundFor(double finalAmount) =>
      (paidAmount - finalAmount).clamp(0, double.infinity);

  factory EarlyCheckOutQuote.fromJson(Map<String, dynamic> json) {
    return EarlyCheckOutQuote(
      actualCheckOutAt:
          DateTime.tryParse(json['actual_check_out_at'] as String? ?? '') ??
          DateTime.now(),
      plannedCheckOutAt:
          DateTime.tryParse(json['planned_check_out_at'] as String? ?? '') ??
          DateTime.now(),
      plannedDays: (json['planned_days'] as num?)?.toInt() ?? 0,
      billedDays: (json['billed_days'] as num?)?.toInt() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      proposedAmount: (json['proposed_amount'] as num?)?.toDouble() ?? 0,
      refundAmount: (json['refund_amount'] as num?)?.toDouble() ?? 0,
    );
  }
}
