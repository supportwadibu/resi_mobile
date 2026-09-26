import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';

import '../../../business_logic/add_reservation_state.dart';

/// Apporteur d'affaire de la réservation : nom, téléphone, et la commission
/// qu'il touchera, annoncée avant l'envoi.
///
/// Facultatif et libre : l'apporteur n'a pas de compte, et n'est souvent
/// connu que de nom.
class ReferrerFields extends StatelessWidget {
  const ReferrerFields({
    required this.state,
    required this.onNameChanged,
    required this.onPhoneChanged,
    super.key,
  });

  final AddReservationState state;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPhoneChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: onNameChanged,
          textCapitalization: TextCapitalization.words,
          decoration: _decoration(context, 'referrer.name_hint'.tr()),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: onPhoneChanged,
          keyboardType: TextInputType.phone,
          decoration: _decoration(context, 'referrer.phone_hint'.tr()),
        ),
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
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              Text(
                CurrencyFormatter.short(state.referrerCommission),
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ],
    );
  }

  InputDecoration _decoration(BuildContext context, String hint) {
    final scheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: scheme.primary),
      ),
    );
  }
}
