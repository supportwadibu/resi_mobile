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
                  reservation.residenceName,
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

class _StatusDot extends StatelessWidget {
  final ReservationStatus status;
  const _StatusDot({required this.status});

  Color get _color {
    switch (status) {
      case ReservationStatus.paid:
        return AppColors.green;
      case ReservationStatus.pending:
        return const Color(0xFFF39C12);
      case ReservationStatus.cancelled:
        return AppColors.red;
    }
  }

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

  String get _label {
    switch (status) {
      case ReservationStatus.paid:
        return 'Réglé';
      case ReservationStatus.pending:
        return 'En attente';
      case ReservationStatus.cancelled:
        return 'Annulé';
    }
  }

  Color get _color {
    switch (status) {
      case ReservationStatus.paid:
        return AppColors.green;
      case ReservationStatus.pending:
        return const Color(0xFFF39C12);
      case ReservationStatus.cancelled:
        return AppColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _label,
      style: AppTextStyles.labelSmall.copyWith(color: _color, fontSize: 10),
    );
  }
}
