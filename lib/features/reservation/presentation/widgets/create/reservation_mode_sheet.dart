import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';

import '../../../business_logic/add_reservation_state.dart';

/// Demande si le client arrive maintenant ou si le séjour est à venir.
///
/// Le choix commande le reste du formulaire : un check-in verrouille la date
/// d'entrée à l'instant présent et crée un séjour « en cours », une
/// réservation future laisse la date au choix et n'immobilise le bien que sur
/// ses dates.
Future<ReservationMode?> showReservationModeSheet(BuildContext context) {
  return showAppSheet<ReservationMode>(
    context: context,
    builder: (sheetContext) => AppSheet(
      title: 'booking_form.new_booking'.tr(),
      description: 'booking_form.mode_question'.tr(),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          AppSheetAction(
            icon: LucideIcons.logIn,
            label: 'booking_form.title_check_in'.tr(),
            description: 'booking_form.mode_check_in_hint'.tr(),
            onTap: () =>
                Navigator.of(sheetContext).pop(ReservationMode.checkIn),
          ),
          AppSheetAction(
            icon: LucideIcons.calendarClock,
            label: 'booking_form.title_future'.tr(),
            description: 'booking_form.mode_future_hint'.tr(),
            onTap: () => Navigator.of(sheetContext).pop(ReservationMode.future),
          ),
        ],
      ),
    ),
  );
}
