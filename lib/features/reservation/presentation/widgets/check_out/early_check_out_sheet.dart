import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';

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
/// Rend la réservation clôturée, ou `null` si le propriétaire renonce.
class EarlyCheckOutSheet extends StatelessWidget {
  const EarlyCheckOutSheet({required this.reservation, super.key});

  final ReservationModel reservation;

  static Future<ReservationModel?> show(
    BuildContext context,
    ReservationModel reservation,
  ) {
    return showModalBottomSheet<ReservationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EarlyCheckOutSheet(reservation: reservation),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<EarlyCheckOutCubit>()..quote(reservation.id, DateTime.now()),
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

      case EarlyCheckOutSuccess(:final reservation):
        Navigator.of(context).pop(reservation);

      default:
        break;
    }
  }

  void _changeDeparture(DateTime value) {
    setState(() => _departure = value);
    context.read<EarlyCheckOutCubit>().quote(widget.reservation.id, value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Le clavier du montant recouvrirait sinon le bouton de validation.
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: BlocConsumer<EarlyCheckOutCubit, EarlyCheckOutState>(
        listener: _onStateChanged,
        builder: (context, state) {
          final quote = switch (state) {
            EarlyCheckOutLoaded(:final quote) => quote,
            EarlyCheckOutError(:final quote?) => quote,
            _ => null,
          };
          final isSubmitting =
              state is EarlyCheckOutLoaded && state.isSubmitting;

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'stay_checkout.early_title'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'stay_checkout.early_body'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
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
                  const Center(child: AppLoader(size: 48))
                else if (quote != null)
                  _QuoteDetails(
                    quote: quote,
                    amount: _amount,
                    enabled: !isSubmitting,
                    onAmountChanged: () => setState(() {}),
                  ),
                if (state case EarlyCheckOutError(:final message)) ...[
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canSubmit(quote, isSubmitting)
                        ? () => context.read<EarlyCheckOutCubit>().submit(
                            widget.reservation.id,
                            _typedAmount!,
                          )
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text('stay_checkout.early_confirm'.tr()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            suffixText: 'F',
            helperText: 'stay_checkout.early_amount_hint'.tr(
              namedArgs: {'amount': formatAmount(quote.proposedAmount)},
            ),
            errorText: exceeds
                ? 'stay_checkout.early_amount_too_high'.tr()
                : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
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
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );
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
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: emphasize ? 15 : 13,
          fontWeight: FontWeight.w600,
          color: emphasize ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
    ],
  );
}
