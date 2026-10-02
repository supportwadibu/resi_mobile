import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/resi_tokens.dart';
import 'app_icon_button.dart';

/// Barre de titre des parcours en étapes.
///
/// Même allure qu'`AppTopBar` — retour à gauche, titre aligné à gauche,
/// filet bas — avec le compteur d'étapes à droite et, si [totalSteps] est
/// fourni, une jauge segmentée sous le titre.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(onBack != null ? 4 : 16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: [
                  if (onBack != null) ...[
                    AppIconButton(
                      icon: LucideIcons.chevronLeft,
                      label: 'common.back'.tr(),
                      onPressed: onBack,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleLarge,
                    ),
                  ),
                  if (_hasProgress)
                    Text(
                      'common.step_of'.tr(
                        namedArgs: {
                          'current': '${currentStep! + 1}',
                          'total': '$totalSteps',
                        },
                      ),
                      style: context.text.bodySmall,
                    ),
                ],
              ),
            ),
            if (_hasProgress)
              Padding(
                padding: EdgeInsets.only(left: onBack != null ? 12 : 0, top: 8),
                child: AppStepProgress(
                  total: totalSteps!,
                  current: currentStep!,
                ),
              ),
          ],
        ),
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
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            height: 4,
            color: i <= current ? t.primary : t.border,
          ),
        );
      }),
    );
  }
}
