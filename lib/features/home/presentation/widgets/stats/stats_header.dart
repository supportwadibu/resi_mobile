import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';

class StatsHeader extends StatelessWidget {
  const StatsHeader({
    super.key,
    required this.from,
    required this.to,
    required this.onPeriodPicked,
  });

  /// Bornes du relevé affiché, reprises telles quelles dans le titre : le
  /// libellé doit décrire la période des chiffres, pas le mois courant.
  final DateTime from;
  final DateTime to;

  final ValueChanged<DateTimeRange> onPeriodPicked;

  /// « Septembre 2026 » quand la période tient dans un mois, « 03/09 - 21/10 »
  /// sinon : le nom du mois devient trompeur dès que la fenêtre le déborde.
  String get _label {
    if (from.year == to.year && from.month == to.month) {
      // Le nom du mois vient d'intl, dans la langue de l'application ; le
      // français l'écrit en minuscule, d'où la majuscule ajoutée.
      return toBeginningOfSentenceCase(DateFormat('MMMM y').format(from));
    }

    String short(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return '${short(from)} - ${short(to)}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('stats.period'.tr(), style: context.text.bodySmall),
              Text(
                _label,
                style: context.text.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        AppButton(
          label: 'stats.change'.tr(),
          icon: LucideIcons.calendarRange,
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.sm,
          onPressed: () async {
            // Le calendrier prend le thème de l'application, clair ou
            // sombre : aucune surcharge de couleurs ici.
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              initialDateRange: DateTimeRange(start: from, end: to),
            );
            if (picked != null) onPeriodPicked(picked);
          },
        ),
      ],
    );
  }
}
