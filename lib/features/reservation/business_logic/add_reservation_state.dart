import '../../clients/data/models/client_model.dart';
import '../data/models/reservation_model.dart';

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
  });

  final ReservationMode mode;

  /// Client choisi au carnet. Non nul, les champs de saisie sont ignorés.
  final ClientModel? selectedClient;

  final String fullName;
  final String phone;
  final String? documentFrontPath;
  final String? documentBackPath;

  final String? propertyId;

  /// Tarif journalier du bien choisi, pour calculer le montant attendu sans
  /// attendre le serveur.
  final double dailyPrice;

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

  /// Tarif d'une unité du type de séjour choisi.
  ///
  /// Reprend les ratios du serveur : la demi-journée vaut la moitié du tarif
  /// journalier, le passage 30 %.
  double get unitPrice => switch (stayType) {
    StayType.fullDay => dailyPrice,
    StayType.halfDay => (dailyPrice * 0.5).roundToDouble(),
    StayType.passage => (dailyPrice * 0.3).roundToDouble(),
  };

  /// Nombre de jours facturés, au minimum un.
  int get daysCount {
    if (stayType != StayType.fullDay) return 1;
    final start = checkInAt;
    final end = checkOutAt;
    if (start == null || end == null) return 1;

    final hours = end.difference(start).inMinutes / 60;
    return hours <= 0 ? 1 : (hours / 24).ceil().clamp(1, 3650);
  }

  /// Montant attendu selon la grille du bien, avant négociation.
  double get expectedAmount => (unitPrice * daysCount).roundToDouble();

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
    );
  }
}
