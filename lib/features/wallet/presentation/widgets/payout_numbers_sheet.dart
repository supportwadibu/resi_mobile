import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/wallet_cubit.dart';
import '../../business_logic/wallet_state.dart';
import '../../data/models/wallet_model.dart';
import 'wave_logo.dart';

/// Feuille des numéros Wave de retrait : deux au plus, choisis à chaque
/// demande. Un numéro vidé est retiré.
///
/// Rend les numéros enregistrés, ou `null` si le propriétaire renonce.
class PayoutNumbersSheet extends StatelessWidget {
  const PayoutNumbersSheet({required this.current, super.key});

  final List<PayoutNumber> current;

  static Future<List<PayoutNumber>?> show(
    BuildContext context,
    List<PayoutNumber> current,
  ) {
    return showAppSheet<List<PayoutNumber>>(
      context: context,
      builder: (_) => PayoutNumbersSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PayoutNumbersCubit>(),
      child: _PayoutNumbersForm(current: current),
    );
  }
}

class _PayoutNumbersForm extends StatefulWidget {
  const _PayoutNumbersForm({required this.current});

  final List<PayoutNumber> current;

  @override
  State<_PayoutNumbersForm> createState() => _PayoutNumbersFormState();
}

class _PayoutNumbersFormState extends State<_PayoutNumbersForm> {
  late final List<TextEditingController> _phones;
  late final List<TextEditingController> _names;

  @override
  void initState() {
    super.initState();
    PayoutNumber? at(int slot) {
      for (final number in widget.current) {
        if (number.slot == slot) return number;
      }
      return null;
    }

    _phones = [
      for (var slot = 1; slot <= PayoutSettings.maxNumbers; slot++)
        TextEditingController(text: at(slot)?.phone ?? ''),
    ];
    _names = [
      for (var slot = 1; slot <= PayoutSettings.maxNumbers; slot++)
        TextEditingController(text: at(slot)?.holderName ?? ''),
    ];
  }

  @override
  void dispose() {
    for (final controller in [..._phones, ..._names]) {
      controller.dispose();
    }
    super.dispose();
  }

  List<PayoutNumber> get _typed => [
    for (var i = 0; i < PayoutSettings.maxNumbers; i++)
      if (_phones[i].text.trim().isNotEmpty)
        PayoutNumber(
          slot: i + 1,
          phone: _phones[i].text.trim(),
          holderName: _names[i].text.trim().isEmpty
              ? null
              : _names[i].text.trim(),
        ),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PayoutNumbersCubit, PayoutNumbersState>(
      listener: (context, state) {
        if (state case PayoutNumbersSaved(:final numbers)) {
          Navigator.of(context).pop(numbers);
        }
      },
      builder: (context, state) {
        final isSaving = state is PayoutNumbersSaving;

        return AppSheet(
          title: 'wallet.payout_numbers_title'.tr(),
          description: 'wallet.payout_numbers_body'.tr(),
          footer: AppButton(
            label: 'wallet.payout_numbers_save'.tr(),
            icon: LucideIcons.check,
            expand: true,
            isLoading: isSaving,
            onPressed: isSaving
                ? null
                : () => context.read<PayoutNumbersCubit>().save(_typed),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < PayoutSettings.maxNumbers; i++) ...[
                if (i > 0) const SizedBox(height: 20),
                Row(
                  children: [
                    const WaveLogo(size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'wallet.payout_number_n'.tr(args: ['${i + 1}']),
                      style: context.text.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                  label: 'wallet.payout_phone'.tr(),
                  hint: 'wallet.payout_phone_hint'.tr(),
                  controller: _phones[i],
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  ],
                  enabled: !isSaving,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  label: 'wallet.payout_name'.tr(),
                  controller: _names[i],
                  enabled: !isSaving,
                ),
              ],
              if (state case PayoutNumbersFailure(:final message)) ...[
                const SizedBox(height: 12),
                AppCallout(
                  icon: LucideIcons.circleAlert,
                  tone: AppAccent.red,
                  message: message,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
