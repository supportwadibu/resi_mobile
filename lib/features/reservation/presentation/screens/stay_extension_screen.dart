import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/utils/currency_formatter.dart';
import '../../data/models/reservation_model.dart';
import '../widgets/extension/booking_info_card.dart';
import '../widgets/extension/extension_header.dart';
import '../widgets/extension/night_counter.dart';
import '../widgets/extension/payment_link_button.dart';
import '../widgets/extension/price_summary_card.dart';

/// Prolongation d'un séjour en cours.
///
/// Le montant affiché reprend le tarif figé à la réservation : le propriétaire
/// peut avoir retouché sa grille depuis, mais un séjour déjà engagé reste
/// facturé aux conditions acceptées. Le serveur reste seul à faire foi sur le
/// montant encaissé.
@RoutePage()
class StayExtensionScreen extends StatefulWidget {
  const StayExtensionScreen({super.key, required this.reservation});

  final ReservationModel reservation;

  @override
  State<StayExtensionScreen> createState() => _StayExtensionScreenState();
}

class _StayExtensionScreenState extends State<StayExtensionScreen> {
  /// Jours ajoutés au séjour, jamais moins d'un.
  int _extraDays = 1;

  static final _dateFormat = DateFormat('d MMMM y', 'fr');

  ReservationModel get _reservation => widget.reservation;

  /// Tarif journalier déjà remisé, tel que facturé sur ce séjour.
  ///
  /// La remise de durée s'appliquait à l'ensemble du séjour : la reconduire sur
  /// les jours ajoutés évite de facturer la prolongation plus cher que les
  /// jours qui la précèdent.
  double get _effectiveDailyPrice {
    final discount = _reservation.durationDiscountPercent;
    return _reservation.dailyPrice * (1 - discount / 100);
  }

  double get _extensionTotal =>
      (_effectiveDailyPrice * _extraDays).roundToDouble();

  DateTime get _newEndDate =>
      _reservation.endDate.add(Duration(days: _extraDays));

  @override
  Widget build(BuildContext context) {
    final property = _reservation.property;

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const ExtensionHeader(),

              const SizedBox(height: 40),

              BookingInfoCard(
                residence: property?.title ?? 'Bien supprimé',
                checkIn: _dateFormat.format(_reservation.startDate),
                checkOut: _dateFormat.format(_reservation.endDate),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      NightCounter(
                        value: _extraDays,
                        onAdd: () => setState(() => _extraDays++),
                        onRemove: () {
                          if (_extraDays > 1) {
                            setState(() => _extraDays--);
                          }
                        },
                      ),

                      const SizedBox(height: 12),
                      Text(
                        'Nouveau départ : ${_dateFormat.format(_newEndDate)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff252B5C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 30),

                      PriceSummaryCard(
                        pricePerDay: CurrencyFormatter.fcfa(
                          _reservation.dailyPrice,
                        ),
                        days: _extraDays,
                        subtotal: CurrencyFormatter.fcfa(_extensionTotal),
                        total: CurrencyFormatter.fcfa(_extensionTotal),
                        discountPercent: _reservation.durationDiscountPercent,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              PaymentLinkButton(
                // TODO(prolongation) : appeler `PATCH /client/bookings/:id` avec
                // la nouvelle date de fin, puis enchaîner sur le paiement. La
                // route côté client existe déjà ; il manque l'entrée
                // correspondante dans `ApiEndpoints` et un cubit dédié.
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mise à jour effectuée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.router.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
