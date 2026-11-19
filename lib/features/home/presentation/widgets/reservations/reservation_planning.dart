import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/reservation/data/models/reservation_model.dart';

/// Un passage au comptoir : une arrivée ou un départ, un jour donné.
typedef _Movement = ({bool arrival, ReservationModel reservation});

/// Planning des maquettes : le mois en grille, un point sous chaque jour qui
/// a une arrivée ou un départ, et sous la grille les mouvements du jour
/// choisi. Les réservations annulées n'y figurent pas : personne ne vient.
class ReservationPlanning extends StatefulWidget {
  const ReservationPlanning({
    required this.reservations,
    this.onChanged,
    super.key,
  });

  final List<ReservationModel> reservations;

  /// Une réservation modifiée depuis sa fiche : la liste se relit.
  final VoidCallback? onChanged;

  @override
  State<ReservationPlanning> createState() => _ReservationPlanningState();
}

class _ReservationPlanningState extends State<ReservationPlanning> {
  late DateTime _month = DateUtils.dateOnly(DateTime.now()).copyWith(day: 1);
  late DateTime _selected = DateUtils.dateOnly(DateTime.now());

  Map<DateTime, List<_Movement>> get _byDay {
    final map = <DateTime, List<_Movement>>{};
    for (final r in widget.reservations) {
      if (r.status == ReservationStatus.cancelled) continue;
      map.putIfAbsent(DateUtils.dateOnly(r.startDate), () => []).add((
        arrival: true,
        reservation: r,
      ));
      map.putIfAbsent(DateUtils.dateOnly(r.endDate), () => []).add((
        arrival: false,
        reservation: r,
      ));
    }
    return map;
  }

  void _shiftMonth(int delta) => setState(() {
    _month = DateTime(_month.year, _month.month + delta);
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final locale = Localizations.localeOf(context).toString();
    final byDay = _byDay;
    final today = DateUtils.dateOnly(DateTime.now());
    // Grille du lundi au dimanche : `weekday` vaut 1 pour lundi.
    final lead = _month.weekday - 1;
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final cells = ((lead + days) / 7).ceil() * 7;
    final moves = byDay[_selected] ?? const <_Movement>[];
    final weekdays = [
      for (var i = 0; i < 7; i++)
        DateFormat.E(locale).format(DateTime(2024, 1, 1 + i)).toUpperCase(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                toBeginningOfSentenceCase(
                  DateFormat.yMMMM(locale).format(_month),
                ),
                style: context.text.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'reservation.planning_previous'.tr(),
              onPressed: () => _shiftMonth(-1),
              icon: Icon(LucideIcons.chevronLeft, size: 18, color: t.muted),
            ),
            IconButton(
              tooltip: 'reservation.planning_next'.tr(),
              onPressed: () => _shiftMonth(1),
              icon: const Icon(LucideIcons.chevronRight, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Text(
                  w.replaceAll('.', ''),
                  textAlign: TextAlign.center,
                  style: context.text.labelSmall!.copyWith(letterSpacing: 0.8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          children: [
            for (var i = 0; i < cells; i++)
              if (i < lead || i >= lead + days)
                const SizedBox.shrink()
              else
                _DayCell(
                  day: DateTime(_month.year, _month.month, i - lead + 1),
                  selected:
                      DateTime(_month.year, _month.month, i - lead + 1) ==
                      _selected,
                  today:
                      DateTime(_month.year, _month.month, i - lead + 1) ==
                      today,
                  busy: byDay.containsKey(
                    DateTime(_month.year, _month.month, i - lead + 1),
                  ),
                  onTap: (d) => setState(() => _selected = d),
                ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                toBeginningOfSentenceCase(
                  DateFormat.MMMMEEEEd(locale).format(_selected),
                ),
                style: context.text.titleMedium,
              ),
            ),
            if (moves.isNotEmpty)
              Text(
                'reservation.planning_moves'.plural(moves.length),
                style: context.text.bodySmall,
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (moves.isEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: t.border),
              borderRadius: AppRadius.lg,
            ),
            child: SizedBox(
              height: 72,
              child: Center(
                child: Text(
                  'reservation.planning_empty'.tr(),
                  style: context.mutedText,
                ),
              ),
            ),
          )
        else
          for (final (i, m) in moves.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            _MovementCard(
              movement: m,
              highlighted: i == 0,
              onChanged: widget.onChanged,
            ),
          ],
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.busy,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final bool busy;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onTap(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected
                  ? t.lavender
                  : busy
                  ? t.foreground.withValues(alpha: 0.06)
                  : t.foreground.withValues(alpha: 0),
              border: Border.all(
                color: today && !selected
                    ? t.foreground.withValues(alpha: 0.4)
                    : t.foreground.withValues(alpha: 0),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: context.text.labelLarge!.copyWith(
                    color: selected ? t.onLavender : t.foreground,
                    fontWeight: selected || today
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (busy && !selected)
                  Positioned(
                    bottom: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.accentViolet,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 4),
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

/// Carte d'un mouvement : heure en pastille, client, résidence, flèche. La
/// première du jour est en lavande, les suivantes neutres.
class _MovementCard extends StatelessWidget {
  const _MovementCard({
    required this.movement,
    required this.highlighted,
    this.onChanged,
  });

  final _Movement movement;
  final bool highlighted;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final r = movement.reservation;
    final fg = highlighted ? t.onLavender : t.foreground;
    final when = movement.arrival ? r.startDate : r.endDate;
    final who = r.client?.fullName ?? '—';
    final where = [
      r.property?.title ?? '',
      'reservation.planning_days'.plural(r.daysCount),
    ].where((s) => s.isNotEmpty).join(' · ');
    return Material(
      color: highlighted ? t.lavender : t.surface,
      shape: AppRadius.outlined(
        AppRadius.lg,
        highlighted ? t.lavender : t.border,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final changed = await context.router.push<bool>(
            DetailsReservationRoute(reservation: r),
          );
          if (changed == true) onChanged?.call();
        },
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: highlighted
                        ? fg.withValues(alpha: 0.1)
                        : movement.arrival
                        ? t.accentVioletSoft
                        : t.accentAmberSoft,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Text(
                      DateFormat.Hm().format(when),
                      style: context.text.labelMedium!.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${movement.arrival ? 'reservation.planning_arrival'.tr() : 'reservation.planning_departure'.tr()} · $who',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall!.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        where,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall!.copyWith(
                          color: fg.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: highlighted ? t.onOverlay : t.background,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 40,
                    child: Icon(
                      LucideIcons.arrowUpRight,
                      size: 15,
                      color: highlighted ? t.onLavender : t.foreground,
                    ),
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
