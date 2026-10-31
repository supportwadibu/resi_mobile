/// Règle de départ d'un bien, miroir de `resolveBilledStay` côté API.
///
/// Un séjour se compte en nuits, et chaque nuit se termine à [checkoutTime]
/// (12h30 par défaut) le lendemain, quelle que soit l'heure d'arrivée : arriver
/// à 10h ou à 22h et partir le lendemain à 12h30 fait une nuit.
///
/// Le dépassement de l'heure de départ est offert jusqu'à [graceMinutes],
/// facturé en demi-nuit jusqu'à [halfDayHours], et entame une nuit au-delà.
/// Lundi 10h → mardi 16h : une nuit et une demi-nuit.
class LateCheckoutPolicy {
  const LateCheckoutPolicy({
    this.checkoutMinutes = defaultCheckoutMinutes,
    this.graceMinutes = defaultGraceMinutes,
    this.halfDayHours = defaultHalfDayHours,
  });

  /// Valeurs du serveur pour un bien qui n'a pas réglé la sienne.
  static const defaultCheckoutTime = '12:30';
  static const defaultCheckoutMinutes = 12 * 60 + 30;
  static const defaultGraceMinutes = 60;
  static const defaultHalfDayHours = 6;

  static final _checkoutTimePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  /// Heure de départ, en minutes depuis minuit (12h30 → 750).
  final int checkoutMinutes;
  final int graceMinutes;
  final int halfDayHours;

  /// Heure de départ « HH:mm » en minutes depuis minuit ; une valeur absente
  /// ou mal formée retombe sur 12h30, comme au serveur.
  static int parseCheckoutTime(String? value) {
    final time = value != null && _checkoutTimePattern.hasMatch(value)
        ? value
        : defaultCheckoutTime;
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Minutes depuis minuit en « HH:mm », pour l'API et l'affichage.
  static String formatCheckoutTime(int minutes) {
    final hours = (minutes ~/ 60).toString().padLeft(2, '0');
    final rest = (minutes % 60).toString().padLeft(2, '0');
    return '$hours:$rest';
  }

  String get checkoutTime => formatCheckoutTime(checkoutMinutes);

  /// Fin de la [nights]-ième nuit : le jour d'arrivée plus [nights] jours, à
  /// l'heure de départ.
  ///
  /// Le jour d'arrivée se lit à l'heure d'Abidjan (UTC+0, sans heure d'été),
  /// comme au serveur : un téléphone réglé sur un autre fuseau annoncerait
  /// sinon une sortie que le serveur ne retiendrait pas.
  DateTime checkOutFor(DateTime checkIn, int nights) {
    final arrival = checkIn.toUtc();
    final deadline = DateTime.utc(
      arrival.year,
      arrival.month,
      arrival.day + (nights < 1 ? 1 : nights),
    ).add(Duration(minutes: checkoutMinutes));
    return checkIn.isUtc ? deadline : deadline.toLocal();
  }

  /// Nuits facturées d'un séjour complet, et départ tardif éventuel.
  ///
  /// [explicitDays] — un nombre de nuits choisi au comptoir — remplace les
  /// nuits écoulées : le dépassement se mesure après l'heure de départ de la
  /// dernière nuit choisie. Au-delà de la demi-nuit, ce choix prime et aucune
  /// nuit n'est ajoutée, comme au serveur.
  BilledStay resolve(DateTime checkIn, DateTime checkOut, {int? explicitDays}) {
    final explicit = explicitDays != null && explicitDays >= 1
        ? explicitDays
        : null;

    final base =
        explicit ?? _elapsedNights(checkIn, checkOut).clamp(1, 3650).toInt();
    final overrun = checkOut.difference(checkOutFor(checkIn, base));

    if (overrun <= Duration(minutes: graceMinutes)) {
      return BilledStay(base, lateCheckout: false);
    }
    if (overrun <= Duration(hours: halfDayHours)) {
      return BilledStay(base, lateCheckout: true);
    }
    if (explicit != null) return BilledStay(base, lateCheckout: false);

    return BilledStay(base + 1, lateCheckout: false);
  }

  /// Nuits dont l'heure de départ est atteinte à [checkOut], éventuellement
  /// zéro.
  int _elapsedNights(DateTime checkIn, DateTime checkOut) {
    final arrival = checkIn.toUtc();
    final departure = checkOut.toUtc();
    final calendarDays = DateTime.utc(
      departure.year,
      departure.month,
      departure.day,
    ).difference(DateTime.utc(arrival.year, arrival.month, arrival.day)).inDays;
    final minuteOfDay = departure.hour * 60 + departure.minute;
    return minuteOfDay >= checkoutMinutes ? calendarDays : calendarDays - 1;
  }

  /// Supplément d'un départ tardif : une demi-nuit au prix [unitPrice],
  /// arrondie au franc comme au serveur.
  static double feeFor(double unitPrice) => (unitPrice * 0.5).roundToDouble();
}

class BilledStay {
  const BilledStay(this.days, {required this.lateCheckout});

  /// Nuits facturées, au minimum une.
  final int days;
  final bool lateCheckout;
}
