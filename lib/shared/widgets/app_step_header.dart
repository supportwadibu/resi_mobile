import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';
import '../../core/theme/app_radius.dart';
import 'app_top_bar.dart';

/// Barre de titre des parcours en étapes, comme `AppTopBar` : retour rond
/// et compteur d'étapes en pilule sur la première ligne, grand titre dessous,
/// jauge segmentée en bas.
///
/// Sans fond propre ni filet : la barre est posée sur le fond de l'écran, qui
/// remonte ainsi jusque sous l'encoche. Un fond blanc ici tranchait avec la
/// zone de l'encoche, restée à la couleur de l'écran.
class AppStepHeader extends StatelessWidget {
  const AppStepHeader({
    super.key,
    required this.title,
    this.onBack,
    this.currentStep,
    this.totalSteps,
  }) : assert(
         currentStep == null || totalSteps != null,
         'currentStep nécessite totalSteps',
       );

  final String title;

  /// Absent, pas de bouton de retour : première étape d'un parcours bloquant.
  final VoidCallback? onBack;

  /// Index de l'étape courante, à partir de 0.
  final int? currentStep;
  final int? totalSteps;

  bool get _hasProgress => currentStep != null && totalSteps != null;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                if (onBack != null) RoundBackButton(onPressed: onBack!),
                const Spacer(),
                if (_hasProgress)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: t.surface,
                      border: Border.all(color: t.border),
                      borderRadius: AppRadius.pill,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        'common.step_of'.tr(
                          namedArgs: {
                            'current': '${currentStep! + 1}',
                            'total': '$totalSteps',
                          },
                        ),
                        style: context.text.labelMedium,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.displaySmall!.copyWith(fontSize: 28),
            ),
          ),
          if (_hasProgress)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
              child: AppStepProgress(total: totalSteps!, current: currentStep!),
            ),
        ],
      ),
    );
  }
}

/// Segments de progression, un par étape.
class AppStepProgress extends StatelessWidget {
  const AppStepProgress({
    super.key,
    required this.total,
    required this.current,
  });

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: List.generate(total, (i) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            height: 6,
            decoration: BoxDecoration(
              color: i <= current ? t.primary : t.border,
              borderRadius: AppRadius.pill,
            ),
          ),
        );
      }),
    );
  }
}
