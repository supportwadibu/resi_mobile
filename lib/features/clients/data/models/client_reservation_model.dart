import 'package:easy_localization/easy_localization.dart';
/// Statut d'un séjour, aligné sur `BOOKING_STATUSES` du serveur.
enum ReservationStatus {
  confirmed('confirmed'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  const ReservationStatus(this.code);

  final String code;

  /// Libellé dans la langue de l'application.
  String get label => 'client_stay_status.$code'.tr();

  static ReservationStatus fromCode(String? code) {
    for (final status in ReservationStatus.values) {
      if (status.code == code) return status;
    }
    // Un statut inconnu vaut mieux affiché comme confirmé que faire échouer la
    // lecture de tout l'historique.
    return ReservationStatus.confirmed;
  }

  /// Le séjour a-t-il compté dans les statistiques du client ?
  ///
  /// Même règle que `COUNTED_STATUSES` côté serveur : une réservation annulée
  /// n'a produit ni séjour ni encaissement.
  bool get countsInStats => this != ReservationStatus.cancelled;
}

/// Un séjour de l'historique d'un client, tel que servi par
/// `GET /proprio/clients/:id/bookings`.
class ClientReservationModel {
  const ClientReservationModel({
    required this.id,
    required this.propertyTitle,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.status,
    this.daysCount = 0,
  });

  final String id;

  /// Titre du bien, joint par le serveur. Vide si le bien a été supprimé
  /// depuis : l'historique du client reste lisible sans lui.
  final String propertyTitle;

  final DateTime startDate;
  final DateTime endDate;

  /// Montant réellement encaissé sur ce séjour.
  final double amount;

  final ReservationStatus status;

  /// Jours d'occupation facturés, figés par le serveur à la réservation.
  final int daysCount;

  factory ClientReservationModel.fromJson(Map<String, dynamic> json) {
    final property = json['property'] as Map<String, dynamic>?;
    final start = _parseDate(json['start_date']) ?? DateTime.now();
    final end = _parseDate(json['end_date']) ?? start;

    return ClientReservationModel(
      id: json['id'] as String? ?? '',
      propertyTitle: property?['title'] as String? ?? '',
      startDate: start,
      endDate: end,
      // `received_amount` n'existe que sur les réservations comptoir, où le
      // montant encaissé peut être négocié sous le tarif. Le repli couvre les
      // réservations en ligne, payées intégralement.
      amount:
          (json['received_amount'] as num?)?.toDouble() ??
          (json['total_amount'] as num?)?.toDouble() ??
          0,
      status: ReservationStatus.fromCode(json['status'] as String?),
      daysCount: (json['days_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Jours d'occupation à afficher.
  ///
  /// Le serveur fige `days_count` à la réservation ; le repli sur l'écart des
  /// dates couvre l'historique antérieur à ce champ.
  int get days =>
      daysCount > 0 ? daysCount : endDate.difference(startDate).inDays;
}

/// Les dates arrivent en ISO 8601 ; une valeur illisible vaut `null` plutôt
/// qu'une exception au milieu du décodage de l'historique.
DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
