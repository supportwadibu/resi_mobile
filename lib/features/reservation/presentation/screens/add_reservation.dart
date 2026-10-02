import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';

import '../../../clients/presentation/widgets/client_picker_sheet.dart';
import '../../../clients/data/services/id_card_reading.dart';
import '../../../clients/data/services/id_scan_service.dart';
import '../../../clients/presentation/widgets/create/client_identity_controller.dart';
import '../../../clients/presentation/widgets/create/client_identity_fields.dart';
import '../../../clients/presentation/widgets/create/id_scan_button.dart';
import '../../../property/business_logic/property_cubit.dart';
import '../../business_logic/add_reservation_cubit.dart';
import '../../business_logic/agreed_price.dart';
import '../../business_logic/add_reservation_state.dart';
import '../widgets/create/client_field_group.dart';
import '../widgets/create/date_time_field.dart';
import '../widgets/create/property_selector.dart';
import '../widgets/create/referrer_fields.dart';
import '../../../subscription/presentation/widgets/plan_gate.dart';
import '../widgets/create/reservation_document_picker.dart';
import '../widgets/create/reservation_section_title.dart';
import '../widgets/create/stay_tier_hints.dart';
import '../widgets/create/stay_type_picker.dart';

/// Enregistrement d'une réservation prise au comptoir.
///
/// Le [mode] vient de la feuille d'entrée : un check-in fixe l'arrivée à
/// l'instant présent et crée un séjour « en cours », une réservation future
/// laisse la date au choix.
@RoutePage()
class AddReservationScreen extends StatelessWidget {
  const AddReservationScreen({this.mode = ReservationMode.checkIn, super.key});

  final ReservationMode mode;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AddReservationCubit>(param1: mode)),
        BlocProvider(create: (_) => sl<PropertyCubit>()..load()),
      ],
      child: const _AddReservationView(),
    );
  }
}

class _AddReservationView extends StatefulWidget {
  const _AddReservationView();

  @override
  State<_AddReservationView> createState() => _AddReservationViewState();
}

class _AddReservationViewState extends State<_AddReservationView> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _depositController = TextEditingController();

  /// Pièce et identité du client nouveau, préremplies par la lecture de la
  /// pièce et reportées au cubit à l'envoi.
  final _identity = ClientIdentityController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _depositController.dispose();
    _identity.dispose();
    super.dispose();
  }

  /// Reporte une lecture de la pièce : un scan remplace la saisie, une photo
  /// déposée dans une case ne comble que les vides.
  void _applyReading(IdCardReading reading, {required bool overwrite}) {
    _identity.apply(reading, overwrite: overwrite);

    final name = reading.fullName;
    if (name != null && (overwrite || _nameController.text.trim().isEmpty)) {
      _nameController.text = name;
      context.read<AddReservationCubit>().setFullName(name);
    }
  }

  /// Lit une face déposée, en arrière-plan : son échec ne se signale pas.
  Future<void> _readDocument(String? path) async {
    if (path == null) return;
    final reading = await const IdScanService().scan(path);
    if (reading == null || !mounted) return;
    _applyReading(reading, overwrite: false);
  }

  void _submit() {
    final cubit = context.read<AddReservationCubit>();
    cubit.setClientIdentity(
      documentType: _identity.documentType,
      documentNumber: _identity.documentNumberValue,
      identity: _identity.identity,
    );
    cubit.submit();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddReservationCubit, AddReservationState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onStatusChanged,
      builder: (context, state) {
        final cubit = context.read<AddReservationCubit>();
        final isCheckIn = state.mode == ReservationMode.checkIn;

        return Scaffold(
          appBar: AppTopBar(
            title: isCheckIn
                ? 'booking_form.title_check_in'.tr()
                : 'booking_form.title_future'.tr(),
          ),
          // Barre fixe : l'enregistrement reste atteignable sans dérouler un
          // formulaire long, au comptoir, client en face.
          bottomNavigationBar: AppBottomActionBar(
            primaryLabel: isCheckIn
                ? 'booking_form.save_check_in'.tr()
                : 'booking_form.save_booking'.tr(),
            primaryIcon: LucideIcons.check,
            isLoading: state.status == AddReservationStatus.submitting,
            onPrimary: state.isValid ? _submit : null,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReservationSectionTitle(title: 'booking_form.client'.tr()),
                ClientFieldGroup(
                  selected: state.selectedClient,
                  nameController: _nameController,
                  phoneController: _phoneController,
                  onNameChanged: cubit.setFullName,
                  onPhoneChanged: cubit.setPhone,
                  onPickFromBook: hasFullPlan()
                      ? () => _pickClient(cubit)
                      : null,
                  onClearSelection: cubit.clearSelectedClient,
                  duplicate: state.duplicateClient,
                  isLookingUp: state.isLookingUpPhone,
                  onUseDuplicate: (client) {
                    cubit.selectClient(client);
                    _nameController.text = client.fullName;
                    _phoneController.text = client.phone;
                  },
                  onDismissDuplicate: cubit.dismissDuplicate,
                ),

                // Les pièces ne concernent qu'un client nouveau : celles d'une
                // fiche existante sont déjà au dossier.
                if (state.selectedClient == null) ...[
                  const SizedBox(height: 20),
                  ReservationSectionTitle(
                    title: 'booking_form.id_optional'.tr(),
                  ),
                  // Tout ce qui est lu voyage avec la réservation, file hors
                  // ligne comprise : le registre de police en dépend.
                  IdScanButton(
                    onScanned: (path, result) {
                      cubit.applyIdScan(path, result);
                      if (result != null) {
                        _applyReading(result, overwrite: true);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ReservationDocumentPicker(
                    frontPath: state.documentFrontPath,
                    backPath: state.documentBackPath,
                    onFrontChanged: (path) {
                      cubit.setDocumentFront(path);
                      _readDocument(path);
                    },
                    onBackChanged: (path) {
                      cubit.setDocumentBack(path);
                      _readDocument(path);
                    },
                  ),
                  const SizedBox(height: 20),
                  ClientIdentityFields(controller: _identity),
                ],

                const SizedBox(height: 24),
                ReservationSectionTitle(title: 'booking_form.residence'.tr()),
                PropertySelector(
                  selectedId: state.propertyId,
                  onSelected: (property) => cubit.setProperty(
                    property.id,
                    dailyPrice: property.pricing.dailyPrice,
                    priceTiers: property.pricing.priceTiers,
                  ),
                ),

                const SizedBox(height: 24),
                ReservationSectionTitle(title: 'booking_form.stay_type'.tr()),
                StayTypePicker(
                  selected: state.stayType,
                  dailyPrice: state.dailyPrice,
                  onSelected: cubit.setStayType,
                ),
                StayTierHints(
                  tiers: state.priceTiers,
                  activeDiscountPercent: state.discountPercent,
                ),

                const SizedBox(height: 24),
                ReservationSectionTitle(
                  title: isCheckIn
                      ? 'booking_form.check_in_now'.tr()
                      : 'booking_form.check_in_date'.tr(),
                ),
                DateTimeField(
                  value: state.checkInAt,
                  enabled: !isCheckIn,
                  firstDate: isCheckIn ? null : DateTime.now(),
                  onChanged: cubit.setCheckIn,
                ),
                const SizedBox(height: 12),
                ReservationSectionTitle(
                  title: 'booking_form.planned_check_out'.tr(),
                ),
                DateTimeField(
                  value: state.checkOutAt,
                  firstDate: state.checkInAt,
                  onChanged: cubit.setCheckOut,
                ),

                if (state.occupiedConflict != null) ...[
                  const SizedBox(height: 12),
                  _ConflictBanner(message: state.occupiedConflict!),
                ],

                const SizedBox(height: 24),
                ReservationSectionTitle(title: 'booking_form.payment'.tr()),
                _AmountSummary(state: state),
                const SizedBox(height: 12),
                // « Prix convenu » et non « Montant reçu » : le serveur en fait
                // le montant du séjour, et l'écart au tarif une remise. Libellé
                // « reçu », il recueillait l'argent versé ce jour-là — un
                // séjour de onze jours enregistré à 15 000 F.
                _AmountField(
                  controller: _amountController,
                  label: 'booking_amounts.agreed_label'.tr(),
                  hint: 'booking_amounts.agreed_hint'.tr(
                    args: [_money(state.expectedAmount)],
                  ),
                  helper: 'booking_amounts.agreed_helper'.tr(),
                  onChanged: (v) => cubit.setReceivedAmount(_parse(v)),
                ),
                if (AgreedPrice.looksLikePayment(
                  expected: state.expectedAmount,
                  agreed: state.receivedAmount,
                )) ...[
                  const SizedBox(height: 8),
                  AppCallout(
                    icon: LucideIcons.triangleAlert,
                    tone: AppAccent.amber,
                    message: 'booking_amounts.suspicious'.tr(
                      args: [_money(state.expectedAmount)],
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
                ReferrerFields(
                  state: state,
                  onEnabledChanged: cubit.setReferrerEnabled,
                  onNameChanged: cubit.setReferrerName,
                  onPhoneChanged: cubit.setReferrerPhone,
                ),

                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ConflictBanner(message: state.errorMessage!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickClient(AddReservationCubit cubit) async {
    final client = await showClientPicker(context);
    if (client == null) return;

    cubit.selectClient(client);
    _nameController.text = client.fullName;
    _phoneController.text = client.phone;
  }

  void _onStatusChanged(BuildContext context, AddReservationState state) {
    final isQueued = state.status == AddReservationStatus.queued;
    if (state.status != AddReservationStatus.success && !isQueued) return;

    // Le routeur est résolu ici, et non dans les rappels : `replace`
    // désactive l'élément de cet écran, si bien qu'un `context.router`
    // évalué plus tard remonterait un ancêtre détruit.
    final router = context.router;
    final mode = state.mode;

    router.replace(
      SuccessRoute(
        title: isQueued
            ? 'booking_form.saved_on_device'.tr()
            : 'booking_form.saved'.tr(),
        // Une saisie hors réseau ne doit pas passer pour confirmée : le
        // propriétaire doit savoir qu'elle attend encore d'être transmise.
        subtitle: isQueued
            ? 'booking_form.queued_hint'.tr()
            : state.mode == ReservationMode.checkIn
            ? 'booking_form.stay_in_progress'.tr()
            : 'booking_form.confirmed'.tr(),
        buttonText: 'booking_form.back_home'.tr(),
        secondaryButtonText: 'booking_form.new_booking'.tr(),
        onPrimaryAction: () => router.replaceAll([const HomeRoute()]),
        onSecondaryAction: () =>
            router.replace(AddReservationRoute(mode: mode)),
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

/// Récapitulatif des montants, recalculé à chaque changement.
class _AmountSummary extends StatelessWidget {
  const _AmountSummary({required this.state});

  final AddReservationState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          // Le détail n'apparaît que lorsqu'un palier joue : sans lui, le
          // montant attendu semblerait ne pas suivre le tarif affiché.
          if (state.discountPercent > 0) ...[
            _Row(
              label: '${state.daysCount} j × ${_money(state.unitPrice)} F',
              value: state.fullAmount,
            ),
            const SizedBox(height: 8),
            // Montant positif, le libellé portant le signe : `_money` groupe
            // les milliers sur les chiffres seuls et décalerait l'espace sur
            // un nombre négatif.
            _Row(
              label: 'booking_form.length_discount'.tr(
                args: ['${state.discountPercent}'],
              ),
              value: state.fullAmount - state.expectedAmount,
            ),
            const Divider(height: 20),
          ],
          _Row(
            label: 'booking_form.expected_amount'.tr(),
            value: state.expectedAmount,
          ),
          if (state.receivedAmount != null &&
              state.receivedAmount != state.expectedAmount) ...[
            // La remise est montrée avant l'envoi : c'est elle qui trahit un
            // versement saisi comme prix du séjour.
            if (AgreedPrice.discount(
                  expected: state.expectedAmount,
                  agreed: state.receivedAmount,
                ) >
                0) ...[
              const SizedBox(height: 8),
              _Row(
                label: 'booking_amounts.negotiated_discount'.tr(),
                value: AgreedPrice.discount(
                  expected: state.expectedAmount,
                  agreed: state.receivedAmount,
                ),
              ),
            ],
            const SizedBox(height: 8),
            _Row(
              label: 'booking_amounts.agreed_label'.tr(),
              value: state.effectiveAmount,
            ),
          ],
          if (state.depositAmount > 0) ...[
            const SizedBox(height: 8),
            _Row(label: 'booking_form.deposit'.tr(), value: state.depositAmount),
            const Divider(height: 20),
            _Row(
              label: 'booking_amounts.balance_due'.tr(),
              value: state.balanceDue,
              strong: true,
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
        Text(
          label,
          style: strong
              ? context.text.titleSmall!.copyWith(fontWeight: FontWeight.w600)
              : context.mutedText,
        ),
        Text(
          '${_money(value)} F',
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

  /// Toujours visible, contrairement à [hint] qui s'efface à la saisie : le
  /// sens du champ doit rester lisible une fois le montant tapé.
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

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCallout(
      icon: LucideIcons.circleAlert,
      tone: AppAccent.red,
      message: message,
    );
  }
}

/// Sépare les milliers par une espace, comme ailleurs dans l'application.
String _money(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }

  return buffer.toString();
}
