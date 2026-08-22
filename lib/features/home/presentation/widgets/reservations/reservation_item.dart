import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/router/app_router.gr.dart';
import '../../../../reservation/data/models/reservation_model.dart';

/// Carte d'une réservation reçue sur un bien du propriétaire.
class ReservationItem extends StatelessWidget {
  const ReservationItem({super.key, required this.reservation});
  final ReservationModel reservation;

  @override
  Widget build(BuildContext context) {
    final property = reservation.property;

    return GestureDetector(
      onTap: () {
        context.router.push(DetailsReservationRoute(reservation: reservation));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Période',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  Text(
                    formatReservationPeriod(reservation),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Montant total',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  Text(
                    formatAmount(reservation.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _Thumbnail(image: property?.image),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property?.title ?? 'Bien supprimé',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          reservation.durationLabel,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (property != null && property.city.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                property.city,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: reservation.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Période du séjour, en dates courtes : « 12 sept. → 14 oct. ».
String formatReservationPeriod(ReservationModel reservation) {
  final format = DateFormat('d MMM', 'fr');
  return '${format.format(reservation.startDate)} → '
      '${format.format(reservation.endDate)}';
}

/// Montant en FCFA, séparateurs de milliers compris.
String formatAmount(double amount) {
  final format = NumberFormat.decimalPattern('fr');
  return '${format.format(amount.round())} F';
}

/// Vignette du bien, tolérante à l'absence de photo.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    final source = image;

    if (source == null || source.isEmpty) return _placeholder();

    return Image.network(
      source,
      width: 64,
      height: 64,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    width: 64,
    height: 64,
    color: Colors.grey.shade200,
    child: const Icon(Icons.image_not_supported_outlined, size: 20),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      ReservationStatus.confirmed => (
        'confirmée',
        const Color(0xFFD1FAE5),
        const Color(0xFF059669),
      ),
      // Le client est dans le logement : distinct de « confirmée », qui décrit
      // un séjour encore à venir.
      ReservationStatus.inProgress => (
        'en cours',
        const Color(0xFFDBEAFE),
        const Color(0xFF2563EB),
      ),
      ReservationStatus.cancelled => (
        'annulée',
        const Color(0xFFFEE2E2),
        const Color(0xFFDC2626),
      ),
      ReservationStatus.completed => (
        'terminée',
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
