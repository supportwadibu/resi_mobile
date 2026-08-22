import '../models/client_reservation_model.dart';

/// Historique de séjours de démonstration, affiché sur la fiche client.
///
/// Vestige de la maquette : le carnet est désormais servi par l'API, mais
/// l'historique par client n'a pas encore d'endpoint dédié. À remplacer par
/// `GET /proprio/bookings?client_id=…` une fois la route exposée.
class ClientsFakeData {
  static final Map<String, List<ClientReservationModel>> reservationsByClient =
      {
        '1': [
          ClientReservationModel(
            id: 'r1',
            residenceName: 'Résidence Les Cocotiers',
            startDate: DateTime(2026, 6, 8),
            endDate: DateTime(2026, 6, 10),
            amount: 45000,
            status: ReservationStatus.paid,
          ),
          ClientReservationModel(
            id: 'r2',
            residenceName: 'Résidence Les Cocotiers',
            startDate: DateTime(2026, 4, 1),
            endDate: DateTime(2026, 4, 4),
            amount: 67500,
            status: ReservationStatus.paid,
          ),
          ClientReservationModel(
            id: 'r3',
            residenceName: 'Villa Bingerville',
            startDate: DateTime(2026, 2, 14),
            endDate: DateTime(2026, 2, 16),
            amount: 40000,
            status: ReservationStatus.pending,
          ),
        ],
        '2': [
          ClientReservationModel(
            id: 'r4',
            residenceName: 'Villa Bingerville',
            startDate: DateTime(2026, 5, 20),
            endDate: DateTime(2026, 5, 22),
            amount: 38000,
            status: ReservationStatus.paid,
          ),
          ClientReservationModel(
            id: 'r5',
            residenceName: 'Villa Bingerville',
            startDate: DateTime(2026, 3, 10),
            endDate: DateTime(2026, 3, 13),
            amount: 37000,
            status: ReservationStatus.cancelled,
          ),
        ],
        '4': [
          ClientReservationModel(
            id: 'r6',
            residenceName: 'Résidence Les Cocotiers',
            startDate: DateTime(2026, 6, 15),
            endDate: DateTime(2026, 6, 18),
            amount: 67500,
            status: ReservationStatus.paid,
          ),
        ],
      };
}
