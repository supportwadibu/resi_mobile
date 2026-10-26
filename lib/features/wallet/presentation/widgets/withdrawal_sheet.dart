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
import '../../business_logic/wallet_cubit.dart';
import '../../business_logic/wallet_state.dart';
import '../../data/models/wallet_model.dart';
import 'wave_logo.dart';

/// Feuille de demande de retrait : montant, numéro Wave enregistré, frais
/// annoncés. Le versement ne passe que par Wave.
///
/// Rend la demande enregistrée, ou `null` si le propriétaire renonce.
class WithdrawalSheet extends StatelessWidget {
  const WithdrawalSheet({
    required this.wallet,
    required this.settings,
    super.key,
  });

  final WalletModel wallet;

  /// Minimum et numéros enregistrés ; au moins un numéro — l'écran fait
  /// enregistrer un numéro avant d'ouvrir la feuille.
  final PayoutSettings settings;

  static Future<WithdrawalModel?> show(
    BuildContext context,
    WalletModel wallet,
    PayoutSettings settings,
  ) {
    return showAppSheet<WithdrawalModel>(
      context: context,
      builder: (_) => WithdrawalSheet(wallet: wallet, settings: settings),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<WithdrawalRequestCubit>(),
      child: _WithdrawalForm(wallet: wallet, settings: settings),
    );
  }
}

class _WithdrawalForm extends StatefulWidget {
  const _WithdrawalForm({required this.wallet, required this.settings});

  final WalletModel wallet;
  final PayoutSettings settings;

  @override
  State<_WithdrawalForm> createState() => _WithdrawalFormState();
}

class _WithdrawalFormState extends State<_WithdrawalForm> {
  // Prérempli du solde entier : le cas courant est de tout retirer.
  late final _amount = TextEditingController(
    text: widget.wallet.balance.toInt().toString(),
  );

  /// Numéro 1 par défaut : c'est le plus souvent celui du propriétaire.
  late int? _slot = widget.settings.numbers.isEmpty
      ? null
      : widget.settings.numbers.first.slot;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  int get _typedAmount => int.tryParse(_amount.text.trim()) ?? 0;

  bool get _amountValid =>
      _typedAmount >= widget.settings.minimumWithdrawal &&
      _typedAmount <= widget.wallet.balance;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WithdrawalRequestCubit, WithdrawalRequestState>(
      listener: (context, state) {
        if (state case WithdrawalRequestSuccess(:final withdrawal)) {
          Navigator.of(context).pop(withdrawal);
        }
      },
      builder: (context, state) {
        final isSubmitting = state is WithdrawalRequestSubmitting;
        final fee = WithdrawalRules.feeFor(
          _typedAmount.toDouble(),
          feeFreeBalance: widget.wallet.feeFreeBalance,
        );
        final slot = _slot;
        final canSubmit = !isSubmitting && _amountValid && slot != null;

        return AppSheet(
          title: 'wallet.withdraw_title'.tr(),
          description: 'wallet.withdraw_body'.tr(
            namedArgs: {
              'balance': CurrencyFormatter.fcfa(widget.wallet.balance),
            },
          ),
          footer: AppButton(
            label: 'wallet.withdraw_confirm'.tr(),
            icon: LucideIcons.arrowDownToLine,
            expand: true,
            isLoading: isSubmitting,
            onPressed: canSubmit
                ? () => context.read<WithdrawalRequestCubit>().submit(
                    widget.wallet.id,
                    amount: _typedAmount,
                    payoutSlot: slot,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'wallet.amount'.tr(),
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !isSubmitting,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const WaveLogo(size: 20),
                  const SizedBox(width: 8),
                  Text('wallet.payout_to'.tr(), style: context.text.titleSmall),
                ],
              ),
              const SizedBox(height: 8),
              for (final number in widget.settings.numbers) ...[
                AppOptionTile(
                  title: 'wallet.payout_number_line'.tr(
                    args: ['${number.slot}', number.phone],
                  ),
                  description: number.holderName,
                  selected: _slot == number.slot,
                  onTap: isSubmitting
                      ? null
                      : () => setState(() => _slot = number.slot),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              // Les frais sont annoncés avant l'envoi : le propriétaire doit
              // savoir ce qu'il recevra, pas le découvrir au versement.
              _Row('wallet.fee'.tr(), '- ${CurrencyFormatter.fcfa(fee)}'),
              const SizedBox(height: 6),
              _Row(
                'wallet.net'.tr(),
                CurrencyFormatter.fcfa(
                  (_typedAmount - fee).clamp(0, double.infinity),
                ),
                emphasize: true,
              ),
              if (_typedAmount > 0 && !_amountValid) ...[
                const SizedBox(height: 12),
                AppCallout(
                  icon: LucideIcons.info,
                  tone: AppAccent.amber,
                  message: 'wallet.amount_invalid'.tr(
                    namedArgs: {
                      'min': CurrencyFormatter.fcfa(
                        widget.settings.minimumWithdrawal,
                      ),
                    },
                  ),
                ),
              ],
              if (state case WithdrawalRequestFailure(:final message)) ...[
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize ? context.text.titleSmall : context.mutedText;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: emphasize ? context.text.amount : style),
      ],
    );
  }
}
