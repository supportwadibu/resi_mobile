import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:intl/intl.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/status_badge.dart';
import '../../data/models/client_reservation_model.dart';

/// Ligne d'un séjour dans l'historique du client.
class ReservationHistoryCard extends StatelessWidget {
  final ClientReservationModel reservation;

  const ReservationHistoryCard({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Vide si le bien a été supprimé depuis : l'historique du
                  // client reste lisible sans lui.
                  reservation.propertyTitle.isEmpty
                      ? 'Bien supprimé'
                      : reservation.propertyTitle,
                  style: context.text.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fmt(reservation.startDate)} → ${_fmt(reservation.endDate)}'
                  ' · ${reservation.days} jour${reservation.days > 1 ? 's' : ''}',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.short(reservation.amount),
                style: context.text.amount,
              ),
              const SizedBox(height: 4),
              StatusBadge(
                label: reservation.status.label,
                tone: StatusTones.booking(reservation.status.code),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => DateFormat('dd MMM', 'fr_FR').format(d);
}
