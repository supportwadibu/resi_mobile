import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

/// Rappel du séjour prolongé : bien, arrivée, fin prévue.
class BookingInfoCard extends StatelessWidget {
  final String residence;
  final String checkIn;
  final String checkOut;

  const BookingInfoCard({
    super.key,
    required this.residence,
    required this.checkIn,
    required this.checkOut,
  });

  @override
  Widget build(BuildContext context) {
    return Section(
      title: residence,
      icon: AppSectionIcons.properties,
      child: DetailList(
        items: [
          DetailItem('Date d\'arrivée', checkIn),
          DetailItem('Fin prévue', checkOut),
        ],
      ),
    );
  }
}
