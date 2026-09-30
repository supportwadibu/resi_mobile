import '../../clients/data/models/client_model.dart';
import '../../property/data/models/property_model.dart';
import '../data/models/reservation_model.dart';
import 'stay_quote.dart';

/// Mode d'enregistrement, choisi à l'ouverture du formulaire.
enum ReservationMode {
  /// Le client se présente maintenant : la réservation naît « en cours ».
  checkIn,

  /// Séjour à venir : la réservation est « confirmée » et n'immobilise le bien
  /// que sur ses dates.
  future,
}

enum AddReservationStatus {
  idle,
  submitting,

  /// Enregistrée sur le serveur.
  success,

  /// Enregistrée sur l'appareil, en attente de réseau.
  ///
  /// Distinct de [success] : la réservation existe et l'argent est encaissé,
  /// mais le serveur l'ignore encore — l'écran doit le dire plutôt que de
  /// laisser croire à une confirmation.
  queued,

  failure,
}

/// Ce que le formulaire connaît à un instant donné.
///
/// Le client est soit choisi au carnet ([selectedClient]), soit saisi
/// ([fullName], [phone]) et créé au moment de l'envoi.
class AddReservationState {
  const AddReservationState({
    required this.mode,
    this.selectedClient,
    this.fullName = '',
    this.phone = '',
    this.documentFrontPath,
    this.documentBackPath,
    this.propertyId,
    this.dailyPrice = 0,
    this.priceTiers = const [],
    this.stayType = StayType.fullDay,
    this.checkInAt,
    this.checkOutAt,
    this.receivedAmount,
    this.depositAmount = 0,
    this.message,
    this.status = AddReservationStatus.idle,
    this.errorMessage,
    this.createdReservation,
    this.duplicateClient,
    this.isLookingUpPhone = false,
    this.occupiedConflict,
    this.hasReferrerEnabled = false,
    this.referrerName = '',
    this.referrerPhone = '',
    this.idDocumentType,
    this.idDocumentNumber,
    this.identity = ClientIdentity.empty,
  });

  final ReservationMode mode;

  /// Client choisi au carnet. Non nul, les champs de saisie sont ignorés.
  final ClientModel? selectedClient;

  final String fullName;
  final String phone;
  final String? documentFrontPath;
  final String? documentBackPath;

  /// Pièce lue par l'OCR. Non lus, ces champs se complètent plus tard depuis
  /// la fiche client.
  final ClientIdDocumentType? idDocumentType;
  final String? idDocumentNumber;

  /// Identité du registre de police, lue sur la pièce ou saisie. Transmise
  /// avec le client nouveau, en ligne comme par la file hors ligne.
  final ClientIdentity identity;

  final String? propertyId;

  /// Tarif journalier du bien choisi, pour calculer le montant attendu sans
  /// attendre le serveur.
  final double dailyPrice;

  /// Grille de remises par durée du bien choisi.
  ///
  /// Vide pour un bien enregistré avant les paliers, comme pour un bien qui
  /// n'en accorde aucun : le tarif plein s'applique alors quelle que soit la
  /// durée.
  final List<PriceTier> priceTiers;

  final StayType stayType;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;

  /// Montant convenu avec le client. `null` tant qu'il n'a pas été saisi : le
  /// montant attendu s'applique alors.
  final double? receivedAmount;
  final double depositAmount;
  final String? message;

  final AddReservationStatus status;
  final String? errorMessage;
  final ReservationModel? createdReservation;

  /// Fiche trouvée pendant la saisie du numéro, à proposer au propriétaire.
  ///
  /// Le téléphone identifie le client : réutiliser la fiche évite un doublon
  /// au carnet et garde justes ses statistiques de séjour.
  final ClientModel? duplicateClient;
  final bool isLookingUpPhone;

  /// Réservation qui empiète sur les dates saisies, détectée avant l'envoi.
  final String? occupiedConflict;

  /// Bascule « apporteur d'affaire ». Éteinte, les champs sont masqués et rien
  /// n'est envoyé.
  final bool hasReferrerEnabled;

  /// Apporteur d'affaire, facultatif. Vide = pas d'apporteur.
  final String referrerName;
  final String referrerPhone;

  /// Taux annoncé au comptoir. Le serveur applique et fige le sien : celui-ci
  /// ne sert qu'à afficher la commission avant l'envoi.
  static const referrerCommissionRate = 0.10;

  bool get hasReferrer => hasReferrerEnabled && referrerName.trim().length >= 2;

  /// Commission annoncée, arrondie au franc comme le fait le serveur.
  double get referrerCommission => hasReferrer
      ? (effectiveAmount * referrerCommissionRate).roundToDouble()
      : 0;

  /// Chiffrage du séjour saisi, partagé avec l'écran de modification.
  StayQuote get quote => StayQuote(
    dailyPrice: dailyPrice,
    priceTiers: priceTiers,
    stayType: stayType,
    checkInAt: checkInAt,
    checkOutAt: checkOutAt,
  );

  double get unitPrice => quote.unitPrice;

  int get daysCount => quote.daysCount;

  int get discountPercent => quote.discountPercent;

  double get expectedAmount => quote.expectedAmount;

  double get fullAmount => quote.fullAmount;

  /// Montant qui sera enregistré : le prix négocié s'il est saisi, le montant
  /// attendu sinon.
  double get effectiveAmount => receivedAmount ?? expectedAmount;

  /// Reste dû après l'acompte, jamais négatif.
  double get balanceDue =>
      (effectiveAmount - depositAmount).clamp(0, double.infinity);

  /// Le formulaire peut-il être envoyé ?
  ///
  /// Un client identifié, un bien, une date d'entrée, et aucun chevauchement
  /// connu. Les pièces d'identité n'en font pas partie : au comptoir, un
  /// client peut ne pas avoir sa pièce, et bloquer l'enregistrement bloquerait
  /// une entrée d'argent.
  bool get isValid {
    final hasClient =
        selectedClient != null ||
        (fullName.trim().length >= 2 && phone.trim().length >= 8);

    return hasClient &&
        (propertyId?.isNotEmpty ?? false) &&
        checkInAt != null &&
        occupiedConflict == null;
  }

  AddReservationState copyWith({
    ReservationMode? mode,
    ClientModel? selectedClient,
    bool clearSelectedClient = false,
    String? fullName,
    String? phone,
    String? documentFrontPath,
    bool clearDocumentFront = false,
    String? documentBackPath,
    bool clearDocumentBack = false,
    String? propertyId,
    double? dailyPrice,
    List<PriceTier>? priceTiers,
    StayType? stayType,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    double? receivedAmount,
    bool clearReceivedAmount = false,
    double? depositAmount,
    String? message,
    AddReservationStatus? status,
    String? errorMessage,
    bool clearError = false,
    ReservationModel? createdReservation,
    ClientModel? duplicateClient,
    bool clearDuplicate = false,
    bool? isLookingUpPhone,
    String? occupiedConflict,
    bool clearConflict = false,
    bool? hasReferrerEnabled,
    String? referrerName,
    String? referrerPhone,
    ClientIdDocumentType? idDocumentType,
    String? idDocumentNumber,
    ClientIdentity? identity,
  }) {
    return AddReservationState(
      mode: mode ?? this.mode,
      selectedClient: clearSelectedClient
          ? null
          : (selectedClient ?? this.selectedClient),
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      documentFrontPath: clearDocumentFront
          ? null
          : (documentFrontPath ?? this.documentFrontPath),
      documentBackPath: clearDocumentBack
          ? null
          : (documentBackPath ?? this.documentBackPath),
      propertyId: propertyId ?? this.propertyId,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      priceTiers: priceTiers ?? this.priceTiers,
      stayType: stayType ?? this.stayType,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      receivedAmount: clearReceivedAmount
          ? null
          : (receivedAmount ?? this.receivedAmount),
      depositAmount: depositAmount ?? this.depositAmount,
      message: message ?? this.message,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdReservation: createdReservation ?? this.createdReservation,
      duplicateClient: clearDuplicate
          ? null
          : (duplicateClient ?? this.duplicateClient),
      isLookingUpPhone: isLookingUpPhone ?? this.isLookingUpPhone,
      occupiedConflict: clearConflict
          ? null
          : (occupiedConflict ?? this.occupiedConflict),
      hasReferrerEnabled: hasReferrerEnabled ?? this.hasReferrerEnabled,
      referrerName: referrerName ?? this.referrerName,
      referrerPhone: referrerPhone ?? this.referrerPhone,
      idDocumentType: idDocumentType ?? this.idDocumentType,
      idDocumentNumber: idDocumentNumber ?? this.idDocumentNumber,
      identity: identity ?? this.identity,
    );
  }
}
