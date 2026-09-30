import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';

import '../../../business_logic/add_reservation_state.dart';

/// Apporteur d'affaire de la réservation : nom, téléphone, et la commission
/// qu'il touchera, annoncée avant l'envoi.
///
/// Facultatif et libre : l'apporteur n'a pas de compte, et n'est souvent
/// connu que de nom. Les champs restent masqués tant que la bascule est
/// éteinte — la plupart des séjours n'en ont pas.
class ReferrerFields extends StatelessWidget {
  const ReferrerFields({
    required this.state,
    required this.onEnabledChanged,
    required this.onNameChanged,
    required this.onPhoneChanged,
    super.key,
  });

  final AddReservationState state;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPhoneChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = state.hasReferrerEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'referrer.section'.tr(),
                    style: context.text.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'referrer.toggle_hint'.tr(),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: onEnabledChanged),
          ],
        ),
        if (enabled) ...[
          const SizedBox(height: 12),
          TextField(
            onChanged: onNameChanged,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'referrer.name_hint'.tr(),
              prefixIcon: const Icon(LucideIcons.user, size: 16),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: onPhoneChanged,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'referrer.phone_hint'.tr(),
              prefixIcon: const Icon(LucideIcons.phone, size: 16),
            ),
          ),
        ],
        if (state.hasReferrer) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'referrer.commission'.tr(
                  args: [
                    '${(AddReservationState.referrerCommissionRate * 100).round()}',
                  ],
                ),
                style: context.text.bodySmall,
              ),
              Text(
                CurrencyFormatter.short(state.referrerCommission),
                style: context.text.amount,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
