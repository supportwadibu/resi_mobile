import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
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

  static DateTime defaultDeparture(ReservationModel reservation) {
    final now = DateTime.now();
    if (now.isBefore(reservation.checkOutAt) &&
        now.isAfter(reservation.checkInAt)) {
      return now;
    }
    if (!now.isBefore(reservation.checkOutAt)) {
      final diff = reservation.checkOutAt.difference(reservation.checkInAt);
      final candidate = reservation.checkInAt.add(diff * 0.8);
      return candidate.isAfter(reservation.checkInAt)
          ? candidate
          : reservation.checkOutAt.subtract(const Duration(hours: 1));
    }
    return reservation.checkInAt.add(const Duration(hours: 1));
  }

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
    final departure = defaultDeparture(reservation);
    return BlocProvider(
      create: (_) =>
          sl<EarlyCheckOutCubit>()
            ..quote(reservation.id, departure, reservation: reservation),
      child: _EarlyCheckOutForm(
        reservation: reservation,
        initialDeparture: departure,
      ),
    );
  }
}

class _EarlyCheckOutForm extends StatefulWidget {
  const _EarlyCheckOutForm({
    required this.reservation,
    required this.initialDeparture,
  });

  final ReservationModel reservation;
  final DateTime initialDeparture;

  @override
  State<_EarlyCheckOutForm> createState() => _EarlyCheckOutFormState();
}

class _EarlyCheckOutFormState extends State<_EarlyCheckOutForm> {
  final _amount = TextEditingController();
  final _penalty = TextEditingController();
  late DateTime _departure = widget.initialDeparture;
  EarlyCheckOutOption _selectedOption = EarlyCheckOutOption.prorata;

  /// Chiffrage dont le montant a été reporté dans le champ.
  ///
  /// Le champ n'est réinitialisé qu'à l'arrivée d'un **nouveau** chiffrage :
  /// un échec d'envoi réémet l'ancien, et écraser alors le montant retouché
  /// effacerait la saisie que le propriétaire veut justement corriger.
  EarlyCheckOutQuote? _filledFrom;

  @override
  void dispose() {
    _amount.dispose();
    _penalty.dispose();
    super.dispose();
  }

  double? get _typedAmount => double.tryParse(_amount.text.trim());
  double? get _typedPenalty => double.tryParse(_penalty.text.trim());

  void _onStateChanged(BuildContext context, EarlyCheckOutState state) {
    switch (state) {
      case EarlyCheckOutLoaded(:final quote)
          when !identical(quote, _filledFrom):
        _filledFrom = quote;
        // Initialiser avec l'option prorata par défaut
        _amount.text = quote.proposedAmount.round().toString();
        if (quote.options.isNotEmpty &&
            quote.options.containsKey(EarlyCheckOutOption.withPenalty)) {
          final penaltyOption = quote.options[EarlyCheckOutOption.withPenalty];
          _penalty.text = penaltyOption?.penalty?.round().toString() ?? '';
        }

      case EarlyCheckOutSuccess():
        Navigator.of(context).pop(state);

      default:
        break;
    }
  }

  void _onOptionChanged(
    EarlyCheckOutOption? option,
    EarlyCheckOutQuote? quote,
  ) {
    if (option == null || quote == null) return;

    setState(() {
      _selectedOption = option;

      // Mettre à jour le montant selon l'option choisie
      final optionDetails = quote.options[option];
      if (optionDetails != null) {
        _amount.text = optionDetails.amount.round().toString();
        if (option == EarlyCheckOutOption.withPenalty &&
            optionDetails.penalty != null) {
          _penalty.text = optionDetails.penalty!.round().toString();
        }
      }
    });
  }

  void _onPenaltyChanged(EarlyCheckOutQuote quote) {
    setState(() {
      if (_selectedOption == EarlyCheckOutOption.withPenalty) {
        final p = double.tryParse(_penalty.text.trim()) ?? 0;
        final prorata =
            quote.options[EarlyCheckOutOption.prorata]?.amount ??
            quote.proposedAmount;
        final total = (prorata + p).clamp(0.0, quote.paidAmount);
        _amount.text = total.round().toString();
      }
    });
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
                ? () {
                    final penalty =
                        _selectedOption == EarlyCheckOutOption.withPenalty
                        ? _typedPenalty
                        : null;
                    context.read<EarlyCheckOutCubit>().submit(
                      widget.reservation.id,
                      _typedAmount!,
                      option: _selectedOption,
                      penaltyAmount: penalty,
                    );
                  }
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
              else if (quote != null) ...[
                _OptionSelector(
                  selectedOption: _selectedOption,
                  quote: quote,
                  enabled: !isSubmitting,
                  onChanged: (option) => _onOptionChanged(option, quote),
                ),
                const SizedBox(height: 20),
                _QuoteDetails(
                  quote: quote,
                  selectedOption: _selectedOption,
                  amount: _amount,
                  penalty: _penalty,
                  enabled: !isSubmitting,
                  onAmountChanged: () => setState(() {}),
                  onPenaltyChanged: () => _onPenaltyChanged(quote),
                ),
              ],
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
    final penalty = _typedPenalty;
    if (_selectedOption == EarlyCheckOutOption.withPenalty &&
        penalty != null &&
        penalty < 0) {
      return false;
    }
    return quote != null &&
        !isSubmitting &&
        amount != null &&
        amount >= 0 &&
        amount <= quote.paidAmount;
  }
}

class _OptionSelector extends StatelessWidget {
  const _OptionSelector({
    required this.selectedOption,
    required this.quote,
    required this.enabled,
    required this.onChanged,
  });

  final EarlyCheckOutOption selectedOption;
  final EarlyCheckOutQuote quote;
  final bool enabled;
  final ValueChanged<EarlyCheckOutOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('stay_checkout.option_label'.tr()),
        const SizedBox(height: 8),
        for (final option in EarlyCheckOutOption.values) ...[
          _OptionCard(
            option: option,
            details: quote.options[option],
            isSelected: option == selectedOption,
            enabled: enabled,
            onTap: () => onChanged(option),
          ),
          if (option != EarlyCheckOutOption.values.last)
            const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.details,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final EarlyCheckOutOption option;
  final EarlyCheckOutOptionDetails? details;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  String _title() => switch (option) {
    EarlyCheckOutOption.prorata => 'stay_checkout.option_prorata'.tr(),
    EarlyCheckOutOption.withPenalty => 'stay_checkout.option_with_penalty'.tr(),
    EarlyCheckOutOption.fullAmount => 'stay_checkout.option_full_amount'.tr(),
  };

  String _description() => switch (option) {
    EarlyCheckOutOption.prorata => 'stay_checkout.option_prorata_desc'.tr(),
    EarlyCheckOutOption.withPenalty =>
      'stay_checkout.option_with_penalty_desc'.tr(),
    EarlyCheckOutOption.fullAmount =>
      'stay_checkout.option_full_amount_desc'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final amount = details != null ? formatAmount(details!.amount) : '';

    return Material(
      color: t.surface,
      shape: AppRadius.outlined(
        AppRadius.md,
        isSelected ? t.primary : t.border,
        isSelected ? 1.5 : 1,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  isSelected ? LucideIcons.circleDot : LucideIcons.circle,
                  color: isSelected ? t.primary : t.muted,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(),
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _description(),
                      style: context.mutedText.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (amount.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  amount,
                  style: context.text.amount.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? t.primary : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteDetails extends StatelessWidget {
  const _QuoteDetails({
    required this.quote,
    required this.selectedOption,
    required this.amount,
    required this.penalty,
    required this.enabled,
    required this.onAmountChanged,
    required this.onPenaltyChanged,
  });

  final EarlyCheckOutQuote quote;
  final EarlyCheckOutOption selectedOption;
  final TextEditingController amount;
  final TextEditingController penalty;
  final bool enabled;
  final VoidCallback onAmountChanged;
  final VoidCallback onPenaltyChanged;

  @override
  Widget build(BuildContext context) {
    final typed = double.tryParse(amount.text.trim());
    final exceeds = typed != null && typed > quote.paidAmount;
    final suggested =
        quote.options[selectedOption]?.amount ?? quote.proposedAmount;
    final defaultPenalty =
        quote.options[EarlyCheckOutOption.withPenalty]?.penalty;

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
        if (selectedOption == EarlyCheckOutOption.withPenalty) ...[
          const SizedBox(height: 20),
          _Label('stay_checkout.penalty_label'.tr()),
          const SizedBox(height: 8),
          TextField(
            controller: penalty,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => onPenaltyChanged(),
            style: context.text.bodyMedium,
            decoration: InputDecoration(
              suffixText: 'F',
              helperText: defaultPenalty != null
                  ? 'stay_checkout.penalty_hint'.tr(
                      namedArgs: {'amount': formatAmount(defaultPenalty)},
                    )
                  : null,
            ),
          ),
        ],
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
              namedArgs: {'amount': formatAmount(suggested)},
            ),
            errorText: exceeds
                ? 'stay_checkout.early_amount_too_high'.tr()
                : null,
          ),
        ),
        const SizedBox(height: 16),
        _Row(
          'stay_checkout.early_refund'.tr(),
          formatAmount(quote.refundFor(typed ?? suggested)),
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
