import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../business_logic/stay_extension_cubit.dart';
import '../../business_logic/stay_extension_state.dart';
import '../../data/models/reservation_model.dart';
import '../widgets/extension/booking_info_card.dart';
import '../widgets/extension/night_counter.dart';
import '../widgets/extension/payment_link_button.dart';
import '../widgets/extension/price_summary_card.dart';

@RoutePage()
class StayExtensionScreen extends StatelessWidget {
  const StayExtensionScreen({super.key, required this.reservation});

  final ReservationModel reservation;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StayExtensionCubit>(),
      child: _StayExtensionView(reservation: reservation),
    );
  }
}

class _StayExtensionView extends StatefulWidget {
  const _StayExtensionView({required this.reservation});

  final ReservationModel reservation;

  @override
  State<_StayExtensionView> createState() => _StayExtensionViewState();
}

class _StayExtensionViewState extends State<_StayExtensionView> {
  int _extraDays = 1;

  static final _dateFormat = DateFormat('d MMMM y', 'fr');

  ReservationModel get _reservation => widget.reservation;

  /// Tarif convenu à la réservation s'il a été négocié, grille sinon : c'est
  /// ce que le serveur facturera pour chaque jour ajouté.
  double get _effectiveDailyPrice => _reservation.extensionDailyRate;

  double get _extensionTotal =>
      (_effectiveDailyPrice * _extraDays).roundToDouble();

  DateTime get _newEndDate =>
      _reservation.endDate.add(Duration(days: _extraDays));

  void _submit() {
    context.read<StayExtensionCubit>().submit(
      bookingId: _reservation.id,
      checkOutAt: _newEndDate,
    );
  }

  void _onStateChanged(BuildContext context, StayExtensionState state) {
    switch (state) {
      case StayExtensionSuccess():
        // Sans `context` : l'écran se referme juste après, et le toast doit
        // survivre à sa disparition pour être lu sur la fiche.
        AppToast.success('Séjour prolongé');
        // `true` signale à l'écran de détail que la réservation a changé : il
        // affiche des dates et un montant que cet envoi vient de réécrire.
        context.router.maybePop(true);

      case StayExtensionConflict(:final message):
        // Un conflit de période n'est pas une panne : le propriétaire doit
        // pouvoir raccourcir sa demande sans quitter l'écran.
        AppToast.warning(message, context: context);

      case StayExtensionFailure(:final message):
        AppToast.error(message, context: context);

      case StayExtensionIdle() || StayExtensionSubmitting():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final property = _reservation.property;

    return BlocConsumer<StayExtensionCubit, StayExtensionState>(
      listener: _onStateChanged,
      builder: (context, state) {
        final isSubmitting = state is StayExtensionSubmitting;

        return Scaffold(
          appBar: const AppTopBar(title: 'Prolonger le séjour'),
          bottomNavigationBar: PaymentLinkButton(
            isLoading: isSubmitting,
            onPressed: isSubmitting ? null : _submit,
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              BookingInfoCard(
                residence: property?.title ?? 'Bien supprimé',
                checkIn: _dateFormat.format(_reservation.startDate),
                checkOut: _dateFormat.format(_reservation.endDate),
              ),
              const SizedBox(height: 12),
              NightCounter(
                value: _extraDays,
                onAdd: isSubmitting
                    ? () {}
                    : () => setState(() => _extraDays++),
                onRemove: isSubmitting
                    ? () {}
                    : () {
                        if (_extraDays > 1) setState(() => _extraDays--);
                      },
              ),
              const SizedBox(height: 12),
              AppCallout(
                icon: LucideIcons.calendarCheck,
                tone: AppAccent.blue,
                title: 'Nouveau départ',
                message: _dateFormat.format(_newEndDate),
              ),
              const SizedBox(height: 12),
              PriceSummaryCard(
                // Un prix négocié se prolonge au prix négocié : c'est lui qui
                // s'affiche, sans ligne de remise. Sinon, la grille puis sa
                // remise de durée, comme avant.
                pricePerDay: CurrencyFormatter.fcfa(
                  _reservation.hasNegotiatedPrice
                      ? _effectiveDailyPrice.roundToDouble()
                      : _reservation.dailyPrice,
                ),
                days: _extraDays,
                subtotal: CurrencyFormatter.fcfa(_extensionTotal),
                total: CurrencyFormatter.fcfa(_extensionTotal),
                discountPercent: _reservation.hasNegotiatedPrice
                    ? 0
                    : _reservation.durationDiscountPercent,
              ),
            ],
          ),
        );
      },
    );
  }
}
