import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';
import 'app_button.dart';
import 'page_header.dart';

/// Échec de chargement, miroir de `ErrorPanel` : pastille rouge, message,
/// bouton « Réessayer ».
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const IconChip(
            icon: LucideIcons.triangleAlert,
            accent: AppAccent.red,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            'error_state.title'.tr(),
            textAlign: TextAlign.center,
            style: context.text.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            message ?? 'error_state.body'.tr(),
            textAlign: TextAlign.center,
            style: context.text.bodyMedium!.copyWith(
              color: context.tokens.muted,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            AppButton(
              label: 'common.retry'.tr(),
              icon: LucideIcons.rotateCw,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    ),
  );
}
