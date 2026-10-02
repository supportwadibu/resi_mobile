import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';

import '../../../../../core/di/service_locator.dart';
import '../../../../home/presentation/widgets/reservations/reservation_item.dart';
import '../../../business_logic/early_check_out_cubit.dart';
import '../../../business_logic/early_check_out_state.dart';
import '../../../data/models/early_check_out_quote.dart';
import '../../../data/models/reservation_model.dart';
import '../create/date_time_field.dart';

/// Feuille de départ anticipé : heure de sortie réelle, chiffrage du serveur
/// et montant retenu.
///
/// Rend le succès de la clôture — enregistrée, ou mise en file hors ligne —,
/// ou `null` si le propriétaire renonce.
class EarlyCheckOutSheet extends StatelessWidget {
  const EarlyCheckOutSheet({required this.reservation, super.key});

  final ReservationModel reservation;

  static Future<EarlyCheckOutSuccess?> show(
    BuildContext context,
    ReservationModel reservation,
  ) {
    return showAppSheet<EarlyCheckOutSuccess>(
      context: context,
      builder: (_) => EarlyCheckOutSheet(reservation: reservation),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<EarlyCheckOutCubit>()..quote(
            reservation.id,
            DateTime.now(),
            reservation: reservation,
          ),
      child: _EarlyCheckOutForm(reservation: reservation),
    );
  }
}

class _EarlyCheckOutForm extends StatefulWidget {
  const _EarlyCheckOutForm({required this.reservation});

  final ReservationModel reservation;

  @override
  State<_EarlyCheckOutForm> createState() => _EarlyCheckOutFormState();
}

class _EarlyCheckOutFormState extends State<_EarlyCheckOutForm> {
  final _amount = TextEditingController();
  DateTime _departure = DateTime.now();

  /// Chiffrage dont le montant a été reporté dans le champ.
  ///
  /// Le champ n'est réinitialisé qu'à l'arrivée d'un **nouveau** chiffrage :
  /// un échec d'envoi réémet l'ancien, et écraser alors le montant retouché
  /// effacerait la saisie que le propriétaire veut justement corriger.
  EarlyCheckOutQuote? _filledFrom;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double? get _typedAmount => double.tryParse(_amount.text.trim());

  void _onStateChanged(BuildContext context, EarlyCheckOutState state) {
    switch (state) {
      case EarlyCheckOutLoaded(:final quote)
          when !identical(quote, _filledFrom):
        _filledFrom = quote;
        _amount.text = quote.proposedAmount.round().toString();

      case EarlyCheckOutSuccess():
        Navigator.of(context).pop(state);

      default:
        break;
    }
  }

  void _changeDeparture(DateTime value) {
    setState(() => _departure = value);
    context.read<EarlyCheckOutCubit>().quote(
      widget.reservation.id,
      value,
      reservation: widget.reservation,
    );
  }

  @override
  Widget build(BuildContext context) {
    // `AppSheet` repousse le contenu au-dessus du clavier : le champ du
    // montant ne recouvre pas le bouton de validation.
    return BlocConsumer<EarlyCheckOutCubit, EarlyCheckOutState>(
      listener: _onStateChanged,
      builder: (context, state) {
        final quote = switch (state) {
          EarlyCheckOutLoaded(:final quote) => quote,
          EarlyCheckOutError(:final quote?) => quote,
          _ => null,
        };
        final isSubmitting = state is EarlyCheckOutLoaded && state.isSubmitting;

        return AppSheet(
          title: 'stay_checkout.early_title'.tr(),
          description: 'stay_checkout.early_body'.tr(),
          footer: AppButton(
            label: 'stay_checkout.early_confirm'.tr(),
            expand: true,
            isLoading: isSubmitting,
            onPressed: _canSubmit(quote, isSubmitting)
                ? () => context.read<EarlyCheckOutCubit>().submit(
                    widget.reservation.id,
                    _typedAmount!,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label('stay_checkout.early_departure'.tr()),
              const SizedBox(height: 8),
              DateTimeField(
                value: _departure,
                firstDate: widget.reservation.checkInAt,
                enabled: !isSubmitting,
                onChanged: _changeDeparture,
              ),
              const SizedBox(height: 20),
              if (state is EarlyCheckOutLoading)
                const Center(child: AppLoader())
              else if (quote != null)
                _QuoteDetails(
                  quote: quote,
                  amount: _amount,
                  enabled: !isSubmitting,
                  onAmountChanged: () => setState(() {}),
                ),
              // Chiffré sur l'appareil faute de réseau : le propriétaire doit
              // savoir que le montant retenu partira tel quel, plus tard.
              if (state case EarlyCheckOutLoaded(isEstimate: true)) ...[
                const SizedBox(height: 12),
                AppCallout(
                  icon: LucideIcons.wifiOff,
                  tone: AppAccent.amber,
                  message: 'stay_checkout.early_estimate'.tr(),
                ),
              ],
              if (state case EarlyCheckOutError(:final message)) ...[
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

  /// Le serveur refuse un montant au-delà du réglé : le bouton aussi, plutôt
  /// que de laisser partir un envoi voué au 422.
  bool _canSubmit(EarlyCheckOutQuote? quote, bool isSubmitting) {
    final amount = _typedAmount;
    return quote != null &&
        !isSubmitting &&
        amount != null &&
        amount >= 0 &&
        amount <= quote.paidAmount;
  }
}

class _QuoteDetails extends StatelessWidget {
  const _QuoteDetails({
    required this.quote,
    required this.amount,
    required this.enabled,
    required this.onAmountChanged,
  });

  final EarlyCheckOutQuote quote;
  final TextEditingController amount;
  final bool enabled;
  final VoidCallback onAmountChanged;

  @override
  Widget build(BuildContext context) {
    final typed = double.tryParse(amount.text.trim());
    final exceeds = typed != null && typed > quote.paidAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row(
          'stay_checkout.early_days'.tr(),
          'stay_checkout.early_days_value'.tr(
            namedArgs: {
              'billed': '${quote.billedDays}',
              'planned': '${quote.plannedDays}',
            },
          ),
        ),
        const SizedBox(height: 12),
        _Row('stay_checkout.early_paid'.tr(), formatAmount(quote.paidAmount)),
        const SizedBox(height: 20),
        _Label('stay_checkout.early_amount'.tr()),
        const SizedBox(height: 8),
        TextField(
          controller: amount,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => onAmountChanged(),
          style: context.text.bodyMedium,
          decoration: InputDecoration(
            suffixText: 'F',
            helperText: 'stay_checkout.early_amount_hint'.tr(
              namedArgs: {'amount': formatAmount(quote.proposedAmount)},
            ),
            errorText: exceeds
                ? 'stay_checkout.early_amount_too_high'.tr()
                : null,
          ),
        ),
        const SizedBox(height: 16),
        _Row(
          'stay_checkout.early_refund'.tr(),
          formatAmount(quote.refundFor(typed ?? quote.proposedAmount)),
          emphasize: true,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: context.text.titleSmall);
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: context.mutedText),
      Text(
        value,
        style: emphasize
            ? context.text.figure.copyWith(fontSize: 18)
            : context.text.amount,
      ),
    ],
  );
}
