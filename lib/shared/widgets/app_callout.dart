import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';

/// Encart d'état : fond d'accent doux, icône au ton plein, titre, message et
/// action éventuelle. Sert aux états qui appellent une attention (dossier à
/// compléter, compte suspendu, envoi hors ligne en attente).
///
/// Le ton suit la grammaire des statuts : vert en règle, ambre en attente
/// d'action, rouge arrêté, bleu pris en compte.
class AppCallout extends StatelessWidget {
  const AppCallout({
    required this.icon,
    this.title,
    this.message,
    this.tone = AppAccent.neutral,
    this.action,
    super.key,
  });

  final IconData icon;
  /// Absent, le message seul occupe l'encart, au ton du texte courant.
  final String? title;
  final String? message;
  final AppAccent tone;

  /// Bouton sous le message, en général un `AppButton` de taille `sm`.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final neutral = tone == AppAccent.neutral;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: neutral ? t.surface : t.accentSoft(tone),
        border: neutral ? Border.all(color: t.border) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              icon,
              size: 20,
              color: neutral ? t.muted : t.accent(tone),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: context.text.titleSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (message != null) ...[
                  if (title != null) const SizedBox(height: 2),
                  Text(
                    message!,
                    style: title == null
                        ? context.text.bodyMedium
                        : context.mutedText,
                  ),
                ],
                if (action != null) ...[const SizedBox(height: 12), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
