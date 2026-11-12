import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../home/presentation/widgets/reservations/reservation_item.dart';
import '../../business_logic/arrival_cubit.dart';
import '../../business_logic/arrival_state.dart';

/// Arrivée d'un client au comptoir : scan de son QR « Démarrer mon séjour »
/// (ou saisie du PIN), encaissement du reste, puis remise des clés.
@RoutePage()
class ArrivalScreen extends StatelessWidget {
  const ArrivalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ArrivalCubit>(),
      child: BlocBuilder<ArrivalCubit, ArrivalState>(
        builder: (context, state) => switch (state) {
          ArrivalScanning(:final message) => _ScanView(message: message),
          ArrivalLookingUp() => Scaffold(
            appBar: AppTopBar(title: 'arrival.title'.tr()),
            body: const Center(child: AppLoader()),
          ),
          ArrivalReady() => _ArrivalView(state: state),
          ArrivalCompleted() => const _CompletedView(),
        },
      ),
    );
  }
}

/// Viseur et saisie du PIN.
class _ScanView extends StatefulWidget {
  const _ScanView({this.message});

  final String? message;

  @override
  State<_ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<_ScanView> {
  final _pin = TextEditingController();

  // Un QR par seconde suffit : chaque lecture lance une requête, et le
  // serveur borne le nombre d'essais.
  final _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _pin.dispose();
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null) context.read<ArrivalCubit>().lookup(code);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      appBar: AppTopBar(title: 'arrival.title'.tr()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('arrival.scan_hint'.tr(), style: context.mutedText),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: AppRadius.lg,
            child: AspectRatio(
              aspectRatio: 1,
              child: ColoredBox(
                color: t.overlay,
                child: MobileScanner(
                  controller: _scanner,
                  onDetect: _onDetect,
                  // Caméra refusée ou absente : le PIN reste possible.
                  errorBuilder: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'arrival.camera_unavailable'.tr(),
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium!.copyWith(
                          color: t.onOverlay,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.message case final message?) ...[
            const SizedBox(height: 16),
            AppCallout(
              icon: LucideIcons.circleAlert,
              tone: AppAccent.red,
              message: message,
            ),
          ],
          const SizedBox(height: 24),
          Section(
            title: 'arrival.pin_title'.tr(),
            icon: LucideIcons.keyRound,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'arrival.pin_label'.tr(),
                  hint: '245-252',
                  controller: _pin,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s-]')),
                    LengthLimitingTextInputFormatter(7),
                  ],
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'arrival.pin_submit'.tr(),
                  icon: LucideIcons.search,
                  variant: AppButtonVariant.secondary,
                  expand: true,
                  onPressed: () =>
                      context.read<ArrivalCubit>().lookup(_pin.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fiche de la réservation : payé, reste, et ce qui bloque l'arrivée.
class _ArrivalView extends StatefulWidget {
  const _ArrivalView({required this.state});

  final ArrivalReady state;

  @override
  State<_ArrivalView> createState() => _ArrivalViewState();
}

class _ArrivalViewState extends State<_ArrivalView> {
  late final _amount = TextEditingController(text: _balanceText);

  String get _balanceText =>
      widget.state.arrival.reservation.balanceDue.round().toString();

  @override
  void didUpdateWidget(covariant _ArrivalView old) {
    super.didUpdateWidget(old);
    // Fiche relue après un encaissement : le champ reprend le nouveau reste.
    if (old.state.arrival != widget.state.arrival) _amount.text = _balanceText;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ArrivalCubit>();
    final ArrivalReady(:arrival, :busy, :message) = widget.state;
    final booking = arrival.reservation;
    final balance = booking.balanceDue;

    return Scaffold(
      appBar: AppTopBar(title: 'arrival.title'.tr(), onBack: cubit.reset),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Section(
            title: 'arrival.booking'.tr(),
            icon: LucideIcons.calendarCheck,
            child: DetailList(
              items: [
                if (booking.property case final property?)
                  DetailItem('arrival.property'.tr(), property.title),
                if (booking.client case final client?)
                  DetailItem('arrival.client'.tr(), client.fullName),
                DetailItem(
                  'arrival.period'.tr(),
                  DateFormatter.stayPeriod(
                    booking.checkInAt,
                    booking.checkOutAt,
                  ),
                ),
                DetailItem(
                  'arrival.payment_option'.tr(),
                  (booking.isDepositBooking
                          ? 'arrival.option_deposit'
                          : 'arrival.option_full')
                      .tr(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Section(
            title: 'arrival.amounts'.tr(),
            icon: LucideIcons.wallet,
            child: DetailList(
              items: [
                DetailItem(
                  'booking_amounts.stay_amount'.tr(),
                  formatAmount(booking.totalAmount),
                ),
                DetailItem(
                  'arrival.paid_online'.tr(),
                  formatAmount(booking.prepaidAmount),
                ),
                if (booking.depositAmount > 0)
                  DetailItem(
                    'arrival.paid_counter'.tr(),
                    formatAmount(booking.depositAmount),
                  ),
                DetailItem(
                  'booking_amounts.balance_due'.tr(),
                  formatAmount(balance),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (arrival.canCheckIn)
            AppCallout(
              icon: LucideIcons.circleCheck,
              tone: AppAccent.green,
              title: 'arrival.ready_title'.tr(),
              message: 'arrival.ready_message'.tr(),
            )
          else if (arrival.blockedByBalance)
            AppCallout(
              icon: LucideIcons.hand,
              tone: AppAccent.amber,
              title: 'arrival.balance_title'.tr(
                namedArgs: {'amount': formatAmount(balance)},
              ),
              message: 'arrival.balance_message'.tr(),
            )
          else
            AppCallout(
              icon: LucideIcons.circleAlert,
              tone: AppAccent.red,
              title: 'arrival.blocked_title'.tr(),
              message: arrival.blockerMessage,
            ),
          if (arrival.blockedByBalance) ...[
            const SizedBox(height: 16),
            Section(
              title: 'arrival.collect_title'.tr(),
              icon: LucideIcons.banknote,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'arrival.collect_label'.tr(),
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'arrival.collect_submit'.tr(),
                    icon: LucideIcons.banknote,
                    expand: true,
                    isLoading: busy,
                    onPressed: busy
                        ? null
                        : () => cubit.collect(
                            double.tryParse(_amount.text.trim()) ?? 0,
                          ),
                  ),
                ],
              ),
            ),
          ],
          if (message != null) ...[
            const SizedBox(height: 16),
            AppCallout(
              icon: LucideIcons.circleAlert,
              tone: AppAccent.red,
              message: message,
            ),
          ],
        ],
      ),
      bottomNavigationBar: AppBottomActionBar(
        primaryLabel: 'arrival.check_in'.tr(),
        primaryIcon: LucideIcons.keyRound,
        isLoading: busy && arrival.canCheckIn,
        // Le serveur refuserait de toute façon : le bouton suit son verdict.
        onPrimary: arrival.canCheckIn && !busy ? cubit.checkIn : null,
      ),
    );
  }
}

/// Arrivée enregistrée : remise des clés.
class _CompletedView extends StatelessWidget {
  const _CompletedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'arrival.title'.tr()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconChip(
                icon: LucideIcons.keyRound,
                accent: AppAccent.green,
                size: 72,
              ),
              const SizedBox(height: 20),
              Text(
                'arrival.done_title'.tr(),
                style: context.text.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'arrival.done_message'.tr(),
                style: context.mutedText,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'arrival.next_client'.tr(),
                icon: LucideIcons.scanLine,
                expand: true,
                onPressed: context.read<ArrivalCubit>().reset,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'arrival.finish'.tr(),
                variant: AppButtonVariant.ghost,
                expand: true,
                // `true` : la liste qui a ouvert l'écran se recharge.
                onPressed: () => context.router.maybePop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
