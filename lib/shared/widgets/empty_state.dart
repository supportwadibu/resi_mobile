import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';
import 'app_button.dart';
import 'page_header.dart';

/// Liste vide, miroir de `EmptyState` du backoffice : icône sur pastille
/// carrée neutre, message en texte secondaire, action éventuelle.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.onAction,
    this.actionLabel,
    this.actionIcon,
  });

  final String message;
  final String? title;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconChip(icon: icon ?? LucideIcons.inbox, size: 44),
          const SizedBox(height: 12),
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.text.bodyMedium!.copyWith(
              color: context.tokens.muted,
            ),
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 20),
            AppButton(
              label: actionLabel!,
              icon: actionIcon,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    ),
  );
}
