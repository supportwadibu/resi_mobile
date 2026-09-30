import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/status_badge.dart';
import 'package:intl/intl.dart';
import '../../../../../core/router/app_router.gr.dart';
import '../../../../reservation/data/models/reservation_model.dart';

/// Ligne d'une réservation reçue sur un bien du propriétaire : vignette,
/// bien, statut, période et montant.
class ReservationItem extends StatelessWidget {
  const ReservationItem({super.key, required this.reservation, this.onChanged});

  final ReservationModel reservation;

  /// Appelé quand la fiche signale que le séjour a changé — une prolongation.
  ///
  /// La carte porte une copie de la réservation : sans ce signal, elle
  /// afficherait les dates d’avant jusqu’au prochain rechargement complet.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final property = reservation.property;
    final status = reservation.status;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: BorderSide(color: t.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final changed = await context.router.push<bool>(
              DetailsReservationRoute(reservation: reservation),
            );
            if (changed == true) onChanged?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(image: property?.image),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              property?.title ?? 'Bien supprimé',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleSmall!.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: status.label,
                            tone: StatusTones.booking(status.code),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.calendar, size: 12, color: t.muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${formatReservationPeriod(reservation)} · '
                              '${reservation.durationLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (property != null && property.city.isNotEmpty) ...[
                            Icon(LucideIcons.mapPin, size: 12, color: t.muted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodySmall,
                              ),
                            ),
                          ] else
                            const Spacer(),
                          Text(
                            formatAmount(reservation.totalAmount),
                            style: context.text.amount,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  static const _size = 56.0;

  final String? image;

  @override
  Widget build(BuildContext context) {
    final source = image;

    if (source == null || source.isEmpty) return _box(context, loading: false);

    return CachedNetworkImage(
      imageUrl: source,
      width: _size,
      height: _size,
      fit: BoxFit.cover,
      placeholder: (context, _) => _box(context, loading: true),
      // Distinct du chargement : une photo injoignable garde l'icône de repli,
      // là où l'indicateur tournerait sans fin.
      errorWidget: (context, _, _) => _box(context, loading: false),
    );
  }

  Widget _box(BuildContext context, {required bool loading}) => Container(
    width: _size,
    height: _size,
    color: context.tokens.background,
    child: Center(
      child: loading
          ? const AppLoader(size: 24)
          : Icon(LucideIcons.bedDouble, size: 20, color: context.tokens.muted),
    ),
  );
}
