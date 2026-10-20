import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

/// Sélecteur du nombre de jours pour un séjour complet (StayType.fullDay).
///
/// Permet au propriétaire ou gérant de définir directement le nombre de jours
/// facturés (ex: 1 jour pour une arrivée à 12h et un départ le lendemain à 15h)
/// sans que le système n'impose arbitrairement 2 jours.
class StayDurationPicker extends StatelessWidget {
  const StayDurationPicker({
    required this.days,
    required this.onChanged,
    this.minDays = 1,
    this.maxDays,
    super.key,
  });

  final int days;
  final ValueChanged<int> onChanged;
  final int minDays;
  final int? maxDays;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final canDecrement = days > minDays;
    final canIncrement = maxDays == null || days < maxDays!;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'booking_form.stay_duration'.tr(),
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'booking_form.days'.plural(days),
                  style: context.text.bodySmall!.copyWith(
                    color: t.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: LucideIcons.minus,
            label: 'booking_form.remove_day'.tr(),
            bordered: true,
            onPressed: canDecrement ? () => onChanged(days - 1) : null,
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$days',
              textAlign: TextAlign.center,
              style: context.text.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AppIconButton(
            icon: LucideIcons.plus,
            label: 'booking_form.add_day'.tr(),
            bordered: true,
            onPressed: canIncrement ? () => onChanged(days + 1) : null,
          ),
        ],
      ),
    );
  }
}
