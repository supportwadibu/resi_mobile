import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import '../../data/models/reservation_model.dart';
import '../../../home/presentation/widgets/reservations/reservation_item.dart';

/// Fiche d'une réservation reçue.
///
/// Les informations du client ne sont pas encore servies par l'API — seul son
/// identifiant l'est. La section correspondante est donc omise plutôt que
/// remplie d'un contact inventé, qu'un propriétaire aurait pu appeler.
@RoutePage()
class DetailsReservationScreen extends StatelessWidget {
  final ReservationModel reservation;

  const DetailsReservationScreen({super.key, required this.reservation});

  /// Date longue : « 12 mai 2026 ».
  static String _longDate(DateTime date) =>
      DateFormat('d MMMM y', 'fr').format(date);

  @override
  Widget build(BuildContext context) {
    final property = reservation.property;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Détails de réservation',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _Cover(image: property?.image),
            ),
            const SizedBox(height: 24),
            Text(
              property?.title ?? 'Bien supprimé',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (property != null && property.city.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    property.city,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 40),
            _buildDetailRow('Date d’entrée', _longDate(reservation.startDate)),
            const SizedBox(height: 20),
            _buildDetailRow('Date de sortie', _longDate(reservation.endDate)),
            const SizedBox(height: 20),
            _buildDetailRow('Durée', reservation.durationLabel),
            const SizedBox(height: 20),
            _buildDetailRow(
              'Montant total',
              formatAmount(reservation.totalAmount),
            ),
            if (reservation.discountAmount > 0) ...[
              const SizedBox(height: 20),
              _buildDetailRow(
                'Remise',
                '- ${formatAmount(reservation.discountAmount)}',
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Statut',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                _StatusBadge(status: reservation.status),
              ],
            ),

            if (reservation.message case final message?
                when message.trim().isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Message du client',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
            ],

            const SizedBox(height: 40),
            // La prolongation n'a de sens que sur un séjour qui n'est ni
            // annulé ni terminé — à venir comme déjà commencé.
            if (reservation.status.isActive)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.router.push(
                    StayExtensionRoute(reservation: reservation),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Prolonger le séjour',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Etat des lieux',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}

/// Visuel du bien réservé, tolérant à l'absence de photo.
class _Cover extends StatelessWidget {
  const _Cover({this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    final source = image;

    if (source == null || source.isEmpty) return _placeholder();

    return Image.network(
      source,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    width: double.infinity,
    height: 200,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_not_supported_outlined, size: 40),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      ReservationStatus.confirmed => (
        'Confirmée',
        const Color(0xFFD1FAE5),
        const Color(0xFF059669),
      ),
      // Le client occupe le logement : distinct de « confirmée », qui décrit
      // un séjour encore à venir.
      ReservationStatus.inProgress => (
        'En cours',
        const Color(0xFFDBEAFE),
        const Color(0xFF2563EB),
      ),
      ReservationStatus.cancelled => (
        'Annulée',
        const Color(0xFFFEE2E2),
        const Color(0xFFDC2626),
      ),
      ReservationStatus.completed => (
        'Terminée',
        Colors.grey.shade100,
        Colors.grey,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}
