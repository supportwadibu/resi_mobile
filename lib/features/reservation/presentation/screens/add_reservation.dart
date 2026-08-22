import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

import '../../../clients/presentation/widgets/client_picker_sheet.dart';
import '../../../property/business_logic/property_cubit.dart';
import '../../business_logic/add_reservation_cubit.dart';
import '../../business_logic/add_reservation_state.dart';
import '../widgets/create/client_field_group.dart';
import '../widgets/create/date_time_field.dart';
import '../widgets/create/property_selector.dart';
import '../widgets/create/reservation_document_picker.dart';
import '../widgets/create/reservation_section_title.dart';
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
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => context.router.maybePop(),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.textPrimary,
                size: 28,
              ),
            ),
            title: Text(
              isCheckIn ? 'Check-in immédiat' : 'Réservation future',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  onPickFromBook: () => _pickClient(cubit),
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
                  ),
                ),

                const SizedBox(height: 24),
                const ReservationSectionTitle(title: 'Type de séjour'),
                StayTypePicker(
                  selected: state.stayType,
                  dailyPrice: state.dailyPrice,
                  onSelected: cubit.setStayType,
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

                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _ConflictBanner(message: state.errorMessage!),
                ],

                const SizedBox(height: 28),
                _SubmitButton(
                  enabled: state.isValid,
                  isSubmitting:
                      state.status == AddReservationStatus.submitting,
                  label: isCheckIn
                      ? 'Enregistrer le check-in'
                      : 'Enregistrer la réservation',
                  onPressed: cubit.submit,
                ),
                const SizedBox(height: 32),
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

    context.router.replace(
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
        onPrimaryAction: () => context.router.replaceAll([const HomeRoute()]),
        onSecondaryAction: () =>
            context.router.replace(AddReservationRoute(mode: state.mode)),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _Row(label: 'Montant attendu', value: state.expectedAmount),
          if (state.receivedAmount != null &&
              state.receivedAmount != state.expectedAmount) ...[
            const SizedBox(height: 8),
            _Row(label: 'Montant convenu', value: state.effectiveAmount),
          ],
          if (state.depositAmount > 0) ...[
            const SizedBox(height: 8),
            _Row(label: 'Acompte', value: state.depositAmount),
            const Divider(height: 20, color: AppColors.divider),
            _Row(label: 'Reste dû', value: state.balanceDue, strong: true),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.strong = false,
  });

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
          style: TextStyle(
            fontSize: 13,
            color: strong ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          '${_money(value)} F',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
            color: strong ? AppColors.primary : AppColors.textPrimary,
          ),
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
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.enabled,
    required this.isSubmitting,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final bool isSubmitting;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled && !isSubmitting ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.grey200,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
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
