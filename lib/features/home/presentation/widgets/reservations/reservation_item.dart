import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/date_formatter.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/status_badge.dart';
import '../../../../../core/router/app_router.gr.dart';
import '../../../../reservation/data/models/reservation_model.dart';
import 'package:resi_africa/shared/widgets/sync_state_badge.dart';

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

    final client = reservation.client?.fullName.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: t.surface,
        shape: AppRadius.outlined(AppRadius.lg, t.border),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            final changed = await context.router.push<bool>(
              DetailsReservationRoute(reservation: reservation),
            );
            if (changed == true) onChanged?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête : vignette, bien et ville, statut.
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.md,
                      child: _Thumbnail(image: property?.image),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property?.title ?? 'home.deleted_property'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleMedium!.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (property != null && property.city.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.mapPin,
                                  size: 13,
                                  color: t.muted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    property.city,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              StatusBadge(
                                label: status.label,
                                tone: StatusTones.booking(status.code),
                              ),
                              // Saisie hors ligne pas encore reçue par le
                              // serveur : le statut affiché n'est qu'une
                              // promesse tant qu'elle n'est pas partie.
                              if (reservation.syncState case final syncState?)
                                SyncStateBadge(state: syncState),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Période et durée, sur un bandeau doux.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.background,
                    borderRadius: AppRadius.md,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendar, size: 15, color: t.muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${formatReservationPeriod(reservation)} · '
                            '${reservation.durationLabel.replaceAll(' ', ' ')}',
                            // Date et heure aux deux bouts ne tiennent pas sur
                            // une ligne : la période passe à la ligne plutôt
                            // que d'être tronquée.
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodySmall!.copyWith(
                              color: t.foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Client et montant.
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
                  child: Row(
                    children: [
                      Icon(LucideIcons.user, size: 15, color: t.muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          client == null || client.isEmpty ? '—' : client,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatAmount(reservation.totalAmount),
                        style: context.text.amount.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
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

/// Période du séjour, à l'heure près :
/// « 14 nov. 2026, 14h42 → 15 nov. 2026, 12h30 ».
///
/// Lit l'entrée et la sortie, pas les dates de début et de fin : un séjour se
/// facture en nuits closes à l'heure de départ, et l'heure fait partie de ce
/// que le propriétaire doit lire.
String formatReservationPeriod(ReservationModel reservation) =>
    DateFormatter.stayPeriod(reservation.checkInAt, reservation.checkOutAt);

/// Montant en FCFA, séparateurs de milliers compris.
String formatAmount(double amount) {
  final format = NumberFormat.decimalPattern();
  return '${format.format(amount.round())} F';
}

/// Vignette du bien, tolérante à l'absence de photo.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.image});

  static const _size = 64.0;

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
