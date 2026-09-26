import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';

/// Pastille de statut. Le libellé porte le sens : la couleur ne fait que le
/// souligner.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.tone = AppAccent.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final AppAccent tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = tone == AppAccent.neutral ? t.muted : t.accent(tone);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone == AppAccent.neutral ? null : t.accentSoft(tone),
        border: tone == AppAccent.neutral ? Border.all(color: t.border) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall!.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
