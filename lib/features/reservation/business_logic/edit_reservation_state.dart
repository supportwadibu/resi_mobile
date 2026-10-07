import '../../property/data/models/property_model.dart';
import '../data/models/reservation_model.dart';
import 'agreed_price.dart';
import 'stay_quote.dart';

enum EditReservationStatus {
  idle,
  submitting,
  success,

  /// Le logement est déjà réservé sur les nouvelles dates.
  ///
  /// Distinct de [failure] : ce n'est pas une panne à réessayer mais un
  /// conflit à arbitrer, et le formulaire doit rester ouvert pour changer les
  /// dates ou le logement.
  conflict,

  failure,
}

/// Ce que le formulaire de modification connaît à un instant donné.
///
/// Le client n'y figure pas : il est figé dans l'instantané de la réservation,
/// et le serveur ne le réécrit pas.
class EditReservationState {
  const EditReservationState({
    required this.original,
    required this.propertyId,
    required this.dailyPrice,
    this.priceTiers = const [],
    required this.stayType,
    required this.checkInAt,
    required this.checkOutAt,
    this.agreedUnitPrice,
    this.depositAmount = 0,
    this.message = '',
    this.status = EditReservationStatus.idle,
    this.errorMessage,
    this.updated,
    this.queued = false,
  });

  /// Point de départ du formulaire.
  ///
  /// Le prix convenu n'est prérempli que s'il a été négocié : un séjour au
  /// tarif doit suivre le tarif quand ses dates changent, et le figer à
  /// l'ancien montant ferait facturer trois jours au prix de deux. Un prix
  /// négocié, lui, est repris tel quel — y compris un prix aberrant, que
  /// l'avertissement signale alors à la réouverture.
  ///
  /// Il est ramené à l'unité sans arrondi : 100 000 F sur trois jours donnent
  /// 33 333,33 F, et le total recalculé retombe sur 100 000 F tant que les
  /// dates ne bougent pas. Arrondir ici décalerait d'un franc un séjour que
  /// le propriétaire n'a fait qu'ouvrir.
  factory EditReservationState.from(ReservationModel reservation) {
    return EditReservationState(
      original: reservation,
      propertyId: reservation.propertyId,
      dailyPrice: reservation.dailyPrice,
      stayType: reservation.stayType,
      // Lues en UTC sur l'API, saisies en heure locale : les champs de date
      // affichent heures et jours tels que le propriétaire les a choisis.
      checkInAt: reservation.checkInAt.toLocal(),
      checkOutAt: reservation.checkOutAt.toLocal(),
      agreedUnitPrice: reservation.discountAmount > 0
          ? reservation.totalAmount /
                (reservation.daysCount > 0 ? reservation.daysCount : 1)
          : null,
      depositAmount: reservation.depositAmount,
      message: reservation.message ?? '',
    );
  }

  final ReservationModel original;

  final String propertyId;
  final double dailyPrice;
  final List<PriceTier> priceTiers;
  final StayType stayType;
  final DateTime checkInAt;
  final DateTime checkOutAt;

  /// Prix convenu par unité du type de séjour. `null` : le tarif s'applique.
  final double? agreedUnitPrice;
  final double depositAmount;
  final String message;

  final EditReservationStatus status;
  final String? errorMessage;

  /// Réservation telle que le serveur l'a réécrite.
  final ReservationModel? updated;

  /// Modification saisie hors ligne, envoyée au retour du réseau.
  final bool queued;

  StayQuote get quote => StayQuote(
    dailyPrice: dailyPrice,
    priceTiers: priceTiers,
    stayType: stayType,
    checkInAt: checkInAt,
    checkOutAt: checkOutAt,
  );

  double get expectedAmount => quote.expectedAmount;

  /// Prix convenu du séjour : prix unitaire convenu × unités facturées.
  /// Suit les dates — même règle que la prolongation côté serveur
  /// (`extendedAgreedAmount`), qui facture les jours ajoutés au tarif
  /// journalier convenu.
  double? get agreedAmount {
    final unit = agreedUnitPrice;
    if (unit == null) return null;
    return (unit * quote.daysCount).roundToDouble();
  }

  double get effectiveAmount => agreedAmount ?? expectedAmount;

  double get negotiatedDiscount =>
      AgreedPrice.discount(expected: expectedAmount, agreed: agreedAmount);

  bool get looksLikePayment => AgreedPrice.looksLikePayment(
    expected: quote.unitPrice,
    agreed: agreedUnitPrice,
  );

  /// Reste dû après l'acompte, jamais négatif.
  double get balanceDue =>
      (effectiveAmount - depositAmount).clamp(0, double.infinity).toDouble();

  bool get hasValidDates => checkOutAt.isAfter(checkInAt);

  bool get canSubmit =>
      hasValidDates &&
      propertyId.isNotEmpty &&
      status != EditReservationStatus.submitting;

  EditReservationState copyWith({
    String? propertyId,
    double? dailyPrice,
    List<PriceTier>? priceTiers,
    StayType? stayType,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    double? agreedUnitPrice,
    bool clearAgreedUnitPrice = false,
    double? depositAmount,
    String? message,
    EditReservationStatus? status,
    String? errorMessage,
    ReservationModel? updated,
    bool? queued,
  }) {
    return EditReservationState(
      original: original,
      propertyId: propertyId ?? this.propertyId,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      priceTiers: priceTiers ?? this.priceTiers,
      stayType: stayType ?? this.stayType,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      agreedUnitPrice: clearAgreedUnitPrice
          ? null
          : (agreedUnitPrice ?? this.agreedUnitPrice),
      depositAmount: depositAmount ?? this.depositAmount,
      message: message ?? this.message,
      status: status ?? this.status,
      // Un message d'erreur ne survit pas à la saisie suivante.
      errorMessage: errorMessage,
      updated: updated ?? this.updated,
      queued: queued ?? this.queued,
    );
  }
}
