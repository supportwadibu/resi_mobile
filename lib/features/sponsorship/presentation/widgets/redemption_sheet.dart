import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_option_tile.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';

import '../../../../core/di/service_locator.dart';
import '../../../wallet/presentation/widgets/wave_logo.dart';
import '../../business_logic/sponsorship_cubit.dart';
import '../../business_logic/sponsorship_state.dart';
import '../../data/models/sponsorship_model.dart';

/// Feuille « Utiliser mes gains » : retrait Wave ou crédit d'abonnement.
///
/// Rend `true` si la demande est enregistrée, `null` si le propriétaire
/// renonce.
class RedemptionSheet extends StatelessWidget {
  const RedemptionSheet({required this.overview, super.key});

  /// Solde, seuil et usages ouverts ; au moins un usage et un solde au seuil
  /// — l'écran n'ouvre pas la feuille sinon.
  final SponsorshipOverview overview;

  static Future<bool?> show(
    BuildContext context,
    SponsorshipOverview overview,
  ) {
    return showAppSheet<bool>(
      context: context,
      builder: (_) => RedemptionSheet(overview: overview),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RedemptionRequestCubit>(),
      child: _RedemptionForm(overview: overview),
    );
  }
}

class _RedemptionForm extends StatefulWidget {
  const _RedemptionForm({required this.overview});

  final SponsorshipOverview overview;

  @override
  State<_RedemptionForm> createState() => _RedemptionFormState();
}

class _RedemptionFormState extends State<_RedemptionForm> {
  // Prérempli du solde entier : le cas courant est de tout utiliser.
  late final _amount = TextEditingController(
    text: widget.overview.balance.floor().toString(),
  );
  final _phone = TextEditingController();
  final _name = TextEditingController();

  late RedemptionType _type = widget.overview.options.first;

  @override
  void dispose() {
    _amount.dispose();
    _phone.dispose();
    _name.dispose();
    super.dispose();
  }

  int get _typedAmount => int.tryParse(_amount.text.trim()) ?? 0;

  bool get _amountValid =>
      _typedAmount >= widget.overview.minimumAmount &&
      _typedAmount <= widget.overview.balance;

  bool get _phoneValid =>
      _type != RedemptionType.withdrawal ||
      _phone.text.replaceAll(RegExp(r'\D'), '').length >= 8;

  @override
  Widget build(BuildContext context) {
    final overview = widget.overview;

    return BlocConsumer<RedemptionRequestCubit, SponsorshipActionState>(
      listener: (context, state) {
        if (state is SponsorshipActionDone) Navigator.of(context).pop(true);
      },
      builder: (context, state) {
        final isSubmitting = state is SponsorshipActionSubmitting;
        final canSubmit = !isSubmitting && _amountValid && _phoneValid;

        return AppSheet(
          title: 'sponsorship.redeem_title'.tr(),
          description: 'sponsorship.redeem_body'.tr(
            namedArgs: {'balance': CurrencyFormatter.fcfa(overview.balance)},
          ),
          footer: AppButton(
            label: 'sponsorship.redeem_confirm'.tr(),
            icon: LucideIcons.gift,
            expand: true,
            isLoading: isSubmitting,
            onPressed: canSubmit
                ? () => context.read<RedemptionRequestCubit>().submit(
                    type: _type,
                    amount: _typedAmount,
                    payoutPhone: _type == RedemptionType.withdrawal
                        ? _phone.text.trim()
                        : null,
                    payoutName:
                        _type == RedemptionType.withdrawal &&
                            _name.text.trim().isNotEmpty
                        ? _name.text.trim()
                        : null,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in overview.options) ...[
                AppOptionTile(
                  title: option.labelKey.tr(),
                  description: 'sponsorship.redemption_hint.${option.code}'
                      .tr(),
                  icon: option == RedemptionType.withdrawal
                      ? LucideIcons.arrowDownToLine
                      : LucideIcons.creditCard,
                  selected: _type == option,
                  onTap: isSubmitting
                      ? null
                      : () => setState(() => _type = option),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              AppTextField(
                label: 'sponsorship.amount'.tr(),
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !isSubmitting,
                onChanged: (_) => setState(() {}),
              ),
              if (_type == RedemptionType.withdrawal) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const WaveLogo(size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'sponsorship.payout_to'.tr(),
                      style: context.text.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                  label: 'sponsorship.payout_phone'.tr(),
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  enabled: !isSubmitting,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'sponsorship.payout_name'.tr(),
                  controller: _name,
                  enabled: !isSubmitting,
                ),
              ],
              if (_typedAmount > 0 && !_amountValid) ...[
                const SizedBox(height: 12),
                AppCallout(
                  icon: LucideIcons.info,
                  tone: AppAccent.amber,
                  message: 'sponsorship.amount_invalid'.tr(
                    namedArgs: {
                      'min': CurrencyFormatter.fcfa(overview.minimumAmount),
                    },
                  ),
                ),
              ],
              if (state case SponsorshipActionFailure(:final message)) ...[
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
