import 'package:auto_route/auto_route.dart';
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
import 'package:easy_localization/easy_localization.dart';

import '../../../clients/presentation/widgets/client_picker_sheet.dart';
import '../../../clients/presentation/widgets/create/id_scan_button.dart';
import '../../../property/business_logic/property_cubit.dart';
import '../../business_logic/add_reservation_cubit.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _depositController.dispose();
    super.dispose();
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
            title: isCheckIn ? 'Check-in immédiat' : 'Réservation future',
          ),
          // Barre fixe : l'enregistrement reste atteignable sans dérouler un
          // formulaire long, au comptoir, client en face.
          bottomNavigationBar: AppBottomActionBar(
            primaryLabel: isCheckIn
                ? 'Enregistrer le check-in'
                : 'Enregistrer la réservation',
            primaryIcon: LucideIcons.check,
            isLoading: state.status == AddReservationStatus.submitting,
            onPrimary: state.isValid ? cubit.submit : null,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ReservationSectionTitle(title: 'Client'),
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
                  const ReservationSectionTitle(
                    title: 'Pièce d’identité (facultative)',
                  ),
                  // La saisie hors ligne garde la photo et le nom lus ; le
                  // numéro de pièce, lui, ne voyage pas dans la file et se
                  // complète depuis la fiche client.
                  IdScanButton(
                    onScanned: (path, result) {
                      cubit.applyIdScan(path, result);
                      if (result != null) {
                        _nameController.text = result.fullName;
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ReservationDocumentPicker(
                    frontPath: state.documentFrontPath,
                    backPath: state.documentBackPath,
                    onFrontChanged: cubit.setDocumentFront,
                    onBackChanged: cubit.setDocumentBack,
                  ),
                ],

                const SizedBox(height: 24),
                const ReservationSectionTitle(title: 'Résidence'),
                PropertySelector(
                  selectedId: state.propertyId,
                  onSelected: (property) => cubit.setProperty(
                    property.id,
                    dailyPrice: property.pricing.dailyPrice,
                    priceTiers: property.pricing.priceTiers,
                  ),
                ),

                const SizedBox(height: 24),
                const ReservationSectionTitle(title: 'Type de séjour'),
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
                  title: isCheckIn ? 'Entrée (maintenant)' : 'Date d’entrée',
                ),
                DateTimeField(
                  value: state.checkInAt,
                  enabled: !isCheckIn,
                  firstDate: isCheckIn ? null : DateTime.now(),
                  onChanged: cubit.setCheckIn,
                ),
                const SizedBox(height: 12),
                const ReservationSectionTitle(title: 'Sortie prévue'),
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
                const ReservationSectionTitle(title: 'Paiement'),
                _AmountSummary(state: state),
                const SizedBox(height: 12),
                _AmountField(
                  controller: _amountController,
                  hint: 'Montant reçu — ${_money(state.expectedAmount)} F',
                  onChanged: (v) => cubit.setReceivedAmount(_parse(v)),
                ),
                const SizedBox(height: 12),
                _AmountField(
                  controller: _depositController,
                  hint: 'Acompte versé (facultatif)',
                  onChanged: (v) => cubit.setDepositAmount(_parse(v) ?? 0),
                ),

                const SizedBox(height: 24),
                ReservationSectionTitle(title: 'referrer.section'.tr()),
                ReferrerFields(
                  state: state,
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
            ? 'Enregistrée sur l’appareil'
            : 'Réservation enregistrée',
        // Une saisie hors réseau ne doit pas passer pour confirmée : le
        // propriétaire doit savoir qu'elle attend encore d'être transmise.
        subtitle: isQueued
            ? 'Elle sera transmise dès le retour de la connexion.'
            : state.mode == ReservationMode.checkIn
            ? 'Le séjour est en cours.'
            : 'La réservation est confirmée.',
        buttonText: 'Retour à l’accueil',
        secondaryButtonText: 'Nouvelle réservation',
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
              label: 'Remise durée (−${state.discountPercent} %)',
              value: state.fullAmount - state.expectedAmount,
            ),
            const Divider(height: 20),
          ],
          _Row(label: 'Montant attendu', value: state.expectedAmount),
          if (state.receivedAmount != null &&
              state.receivedAmount != state.expectedAmount) ...[
            const SizedBox(height: 8),
            _Row(label: 'Montant convenu', value: state.effectiveAmount),
          ],
          if (state.depositAmount > 0) ...[
            const SizedBox(height: 8),
            _Row(label: 'Acompte', value: state.depositAmount),
            const Divider(height: 20),
            _Row(label: 'Reste dû', value: state.balanceDue, strong: true),
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
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: context.text.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
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
