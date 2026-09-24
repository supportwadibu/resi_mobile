import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import '../../data/models/client_reservation_model.dart';

class ReservationHistoryCard extends StatelessWidget {
  final ClientReservationModel reservation;

  const ReservationHistoryCard({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          _StatusDot(status: reservation.status),
          const SizedBox(width: 12),
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
                  style: AppTextStyles.valueSmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(reservation.startDate)} → ${_fmt(reservation.endDate)}  ·  ${reservation.days} jour${reservation.days > 1 ? 's' : ''}',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(reservation.amount),
                style: AppTextStyles.valueSmall,
              ),
              const SizedBox(height: 4),
              _StatusLabel(status: reservation.status),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => DateFormat('dd MMM', 'fr_FR').format(d);
}

/// Couleur d'un statut de séjour, partagée par la pastille et le libellé.
Color _statusColor(ReservationStatus status) {
  switch (status) {
    case ReservationStatus.completed:
      return AppColors.green;
    case ReservationStatus.inProgress:
    case ReservationStatus.confirmed:
      return const Color(0xFFF39C12);
    case ReservationStatus.cancelled:
      return AppColors.red;
  }
}

class _StatusDot extends StatelessWidget {
  final ReservationStatus status;
  const _StatusDot({required this.status});

  Color get _color => _statusColor(status);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final ReservationStatus status;
  const _StatusLabel({required this.status});

  String get _label => status.label;

  Color get _color => _statusColor(status);

  @override
  Widget build(BuildContext context) {
    return Text(
      _label,
      style: AppTextStyles.labelSmall.copyWith(color: _color, fontSize: 10),
    );
  }
}
