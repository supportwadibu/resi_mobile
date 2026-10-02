import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/di/service_locator.dart';
import '../../core/offline/offline_status.dart';
import '../../core/theme/resi_tokens.dart';
import 'app_callout.dart';

/// Annonce que l'écran montre des données gardées sur l'appareil, et de quand
/// elles datent.
///
/// Sans lui, un chiffre lu hors ligne passerait pour à jour : le propriétaire
/// doit savoir qu'une réservation prise ailleurs depuis peut manquer.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DateTime?>(
      valueListenable: sl<OfflineStatus>(),
      builder: (context, cachedAt, _) {
        if (cachedAt == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: AppCallout(
            icon: LucideIcons.wifiOff,
            tone: AppAccent.neutral,
            message: label(cachedAt, context.locale.toLanguageTag()),
          ),
        );
      },
    );
  }

  @visibleForTesting
  static String label(DateTime cachedAt, String locale) {
    final local = cachedAt.toLocal();
    return 'offline_banner.message'.tr(
      namedArgs: {
        'date': DateFormat.yMd(locale).format(local),
        'time': DateFormat.Hm(locale).format(local),
      },
    );
  }
}
