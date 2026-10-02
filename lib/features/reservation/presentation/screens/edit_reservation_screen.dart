import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';

import '../../../property/business_logic/property_cubit.dart';
import '../../../property/business_logic/property_state.dart';
import '../../business_logic/edit_reservation_cubit.dart';
import '../../business_logic/edit_reservation_state.dart';
import '../../data/models/reservation_model.dart';
import '../widgets/create/date_time_field.dart';
import '../widgets/create/property_selector.dart';
import '../widgets/create/reservation_section_title.dart';
import '../widgets/create/stay_tier_hints.dart';
import '../widgets/create/stay_type_picker.dart';

/// Modification d'une réservation comptoir non terminée : logement, type de
/// séjour, dates, prix convenu, acompte, message.
///
/// Le client ne se change pas ici : il est figé dans l'instantané de la
/// réservation. Une erreur de client se corrige sur sa fiche, ou en annulant
/// pour ressaisir.
///
/// Rend `true` quand la réservation a changé : la fiche appelante, qui ne
/// sait pas se relire, se referme et la liste recharge.
@RoutePage()
class EditReservationScreen extends StatelessWidget {
  const EditReservationScreen({required this.reservation, super.key});

  final ReservationModel reservation;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<EditReservationCubit>(param1: reservation),
        ),
        BlocProvider(create: (_) => sl<PropertyCubit>()..load()),
      ],
      child: const _EditReservationView(),
    );
  }
}

class _EditReservationView extends StatefulWidget {
  const _EditReservationView();

  @override
  State<_EditReservationView> createState() => _EditReservationViewState();
}

class _EditReservationViewState extends State<_EditReservationView> {
  late final TextEditingController _agreedController;
  late final TextEditingController _depositController;
  late final TextEditingController _messageController;

  /// La grille du logement d'origine n'est appliquée qu'une fois : un
  /// rechargement des biens ne doit pas écraser un logement choisi depuis.
  bool _pricingLoaded = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<EditReservationCubit>().state;
    _agreedController = TextEditingController(
      text: state.agreedAmount == null ? '' : _digits(state.agreedAmount!),
    );
    _depositController = TextEditingController(
      text: state.depositAmount > 0 ? _digits(state.depositAmount) : '',
    );
    _messageController = TextEditingController(text: state.message);
  }

  @override
  void dispose() {
    _agreedController.dispose();
    _depositController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onPropertiesLoaded(BuildContext context, PropertyState properties) {
    if (_pricingLoaded || properties is! PropertyLoaded) return;
    final cubit = context.read<EditReservationCubit>();

    for (final property in properties.items) {
      if (property.id == cubit.state.propertyId) {
        cubit.setProperty(property);
        break;
      }
    }
    _pricingLoaded = true;
  }

  void _onStatusChanged(BuildContext context, EditReservationState state) {
    switch (state.status) {
      case EditReservationStatus.success:
        // Sans `context` : l'écran se referme juste après, et le toast doit
        // survivre à sa disparition pour être lu sur la liste.
        AppToast.success(
          state.queued
              ? 'offline_queue.saved'.tr()
              : 'booking_edit.success'.tr(),
        );
        context.router.maybePop(true);
      case EditReservationStatus.conflict:
        // Un conflit n'est pas une panne : le formulaire reste ouvert pour
        // changer les dates ou le logement.
        AppToast.warning(state.errorMessage ?? '', context: context);
      case EditReservationStatus.failure:
        AppToast.error(state.errorMessage ?? '', context: context);
      case EditReservationStatus.idle || EditReservationStatus.submitting:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PropertyCubit, PropertyState>(
      listener: _onPropertiesLoaded,
      child: BlocConsumer<EditReservationCubit, EditReservationState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: _onStatusChanged,
        builder: (context, state) {
          final cubit = context.read<EditReservationCubit>();
          final client = state.original.client;

          return Scaffold(
            appBar: AppTopBar(title: 'booking_edit.title'.tr()),
            bottomNavigationBar: AppBottomActionBar(
              primaryLabel: 'booking_edit.submit'.tr(),
              primaryIcon: LucideIcons.check,
              isLoading: state.status == EditReservationStatus.submitting,
              onPrimary: state.canSubmit ? cubit.submit : null,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (client != null) ...[
                    ReservationSectionTitle(title: 'booking_edit.client'.tr()),
                    AppCard(
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.user,
                            size: 16,
                            color: context.tokens.muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              client.phone.isEmpty
                                  ? client.fullName
                                  : '${client.fullName} · ${client.phone}',
                              style: context.text.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'booking_edit.client_hint'.tr(),
                      style: context.text.bodySmall,
                    ),
                    const SizedBox(height: 24),
                  ],

                  ReservationSectionTitle(title: 'booking_edit.property'.tr()),
                  PropertySelector(
                    selectedId: state.propertyId,
                    onSelected: cubit.setProperty,
                  ),

                  const SizedBox(height: 24),
                  ReservationSectionTitle(title: 'booking_edit.stay_type'.tr()),
                  StayTypePicker(
                    selected: state.stayType,
                    dailyPrice: state.dailyPrice,
                    onSelected: cubit.setStayType,
                  ),
                  StayTierHints(
                    tiers: state.priceTiers,
                    activeDiscountPercent: state.quote.discountPercent,
                  ),

                  const SizedBox(height: 24),
                  ReservationSectionTitle(title: 'booking_edit.check_in'.tr()),
                  DateTimeField(
                    value: state.checkInAt,
                    onChanged: cubit.setCheckIn,
                  ),
                  const SizedBox(height: 12),
                  ReservationSectionTitle(title: 'booking_edit.check_out'.tr()),
                  DateTimeField(
                    value: state.checkOutAt,
                    firstDate: state.checkInAt,
                    onChanged: cubit.setCheckOut,
                  ),
                  if (!state.hasValidDates) ...[
                    const SizedBox(height: 8),
                    AppCallout(
                      icon: LucideIcons.circleAlert,
                      tone: AppAccent.red,
                      message: 'booking_edit.invalid_dates'.tr(),
                    ),
                  ],

                  const SizedBox(height: 24),
                  ReservationSectionTitle(title: 'booking_edit.payment'.tr()),
                  _Summary(state: state),
                  const SizedBox(height: 12),
                  _AmountField(
                    controller: _agreedController,
                    label: 'booking_amounts.agreed_label'.tr(),
                    hint: 'booking_amounts.agreed_hint'.tr(
                      args: [_digits(state.expectedAmount)],
                    ),
                    helper: 'booking_amounts.agreed_helper'.tr(),
                    onChanged: (v) => cubit.setAgreedAmount(_parse(v)),
                  ),
                  if (state.looksLikePayment) ...[
                    const SizedBox(height: 8),
                    AppCallout(
                      icon: LucideIcons.triangleAlert,
                      tone: AppAccent.amber,
                      message: 'booking_amounts.suspicious'.tr(
                        args: [_digits(state.expectedAmount)],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _AmountField(
                    controller: _depositController,
                    label: 'booking_amounts.deposit_label'.tr(),
                    hint: 'booking_amounts.deposit_hint'.tr(),
                    onChanged: (v) => cubit.setDepositAmount(_parse(v) ?? 0),
                  ),

                  const SizedBox(height: 24),
                  ReservationSectionTitle(title: 'booking_edit.message'.tr()),
                  TextField(
                    controller: _messageController,
                    onChanged: cubit.setMessage,
                    maxLines: 3,
                    maxLength: 500,
                    style: context.text.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'booking_edit.message_hint'.tr(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Une saisie libre peut contenir des espaces de milliers ou une virgule.
  static double? _parse(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}

/// Montant sans décimale ni devise, pour préremplir un champ ou un indice.
String _digits(double value) => value.round().toString();

/// Récapitulatif recalculé à chaque changement, sur la grille courante.
class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final EditReservationState state;

  @override
  Widget build(BuildContext context) {
    final quote = state.quote;

    return AppCard(
      child: Column(
        children: [
          if (quote.discountPercent > 0) ...[
            _Row(
              label: 'booking_edit.days_times_price'.tr(
                args: [
                  '${quote.daysCount}',
                  CurrencyFormatter.fcfa(quote.unitPrice),
                ],
              ),
              value: quote.fullAmount,
            ),
            const SizedBox(height: 8),
            _Row(
              label: 'booking_edit.duration_discount'.tr(
                args: ['${quote.discountPercent}'],
              ),
              value: quote.fullAmount - quote.expectedAmount,
            ),
            const Divider(height: 20),
          ],
          _Row(
            label: 'booking_amounts.grid_price'.tr(),
            value: state.expectedAmount,
          ),
          if (state.negotiatedDiscount > 0) ...[
            const SizedBox(height: 8),
            _Row(
              label: 'booking_amounts.negotiated_discount'.tr(),
              value: state.negotiatedDiscount,
            ),
          ],
          const Divider(height: 20),
          _Row(
            label: 'booking_amounts.stay_amount'.tr(),
            value: state.effectiveAmount,
            strong: true,
          ),
          if (state.depositAmount > 0) ...[
            const SizedBox(height: 8),
            _Row(
              label: 'booking_amounts.deposit_label'.tr(),
              value: state.depositAmount,
            ),
            const SizedBox(height: 8),
            _Row(
              label: 'booking_amounts.balance_due'.tr(),
              value: state.balanceDue,
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.strong = false});

  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: strong
                ? context.text.titleSmall!.copyWith(fontWeight: FontWeight.w600)
                : context.mutedText,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          CurrencyFormatter.fcfa(value),
          style: strong
              ? context.text.figure.copyWith(fontSize: 18)
              : context.text.amount,
        ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.helper,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? helper;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: context.text.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 3,
        prefixIcon: const Icon(LucideIcons.banknote, size: 16),
      ),
    );
  }
}
