/// Règle de départ tardif d'un bien, miroir de `resolveBilledStay` côté API.
///
/// Les jours entiers écoulés sont dus ; le dépassement est offert jusqu'à
/// [graceMinutes], facturé en demi-journée jusqu'à [halfDayHours], et entame
/// un jour au-delà. Lundi 12h → mardi 16h : un jour et une demi-journée.
class LateCheckoutPolicy {
  const LateCheckoutPolicy({
    this.graceMinutes = defaultGraceMinutes,
    this.halfDayHours = defaultHalfDayHours,
  });

  /// Valeurs du serveur pour un bien qui n'a pas réglé la sienne.
  static const defaultGraceMinutes = 60;
  static const defaultHalfDayHours = 6;

  final int graceMinutes;
  final int halfDayHours;

  /// Jours facturés d'un séjour complet, et départ tardif éventuel.
  ///
  /// [explicitDays] — un nombre de jours choisi au comptoir — remplace les
  /// jours entiers : le dépassement se mesure au-delà. Au-delà de la
  /// demi-journée, ce choix prime et aucun jour n'est ajouté, comme au
  /// serveur.
  BilledStay resolve(DateTime checkIn, DateTime checkOut, {int? explicitDays}) {
    final elapsed = checkOut.difference(checkIn);
    final explicit = explicitDays != null && explicitDays >= 1
        ? explicitDays
        : null;

    final base =
        explicit ??
        (elapsed.inMilliseconds ~/ Duration.millisecondsPerDay).clamp(1, 3650);
    final overrun = elapsed - Duration(days: base);

    if (overrun <= Duration(minutes: graceMinutes)) {
      return BilledStay(base, lateCheckout: false);
    }
    if (overrun <= Duration(hours: halfDayHours)) {
      return BilledStay(base, lateCheckout: true);
    }
    if (explicit != null) return BilledStay(base, lateCheckout: false);

    return BilledStay(base + 1, lateCheckout: false);
  }

  /// Supplément d'un départ tardif : une demi-journée au prix [unitPrice],
  /// arrondie au franc comme au serveur.
  static double feeFor(double unitPrice) => (unitPrice * 0.5).roundToDouble();
}

class BilledStay {
  const BilledStay(this.days, {required this.lateCheckout});

  final int days;
  final bool lateCheckout;
}
