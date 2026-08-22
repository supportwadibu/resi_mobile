import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

/// Barre de titre des parcours en étapes.
///
/// Remplace `AppBar` sur les écrans du flux d'enregistrement : bouton de
/// retour carré, titre centré, et compteur d'étapes à droite. La barre de
/// progression n'apparaît que si [totalSteps] est fourni, ce qui permet de
/// réutiliser le même header sur un écran à page unique.
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

  /// Absent, le bouton de retour laisse un vide de même largeur pour que le
  /// titre reste optiquement centré.
  final VoidCallback? onBack;

  /// Index de l'étape courante, à partir de 0.
  final int? currentStep;
  final int? totalSteps;

  bool get _hasProgress => currentStep != null && totalSteps != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              if (onBack != null)
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: AppColors.black,
                    ),
                  ),
                )
              else
                const SizedBox(width: 38, height: 38),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
              if (_hasProgress)
                Text(
                  '${currentStep! + 1}/$totalSteps',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                )
              else
                const SizedBox(width: 38),
            ],
          ),
          if (_hasProgress) ...[
            const SizedBox(height: 14),
            AppStepProgress(total: totalSteps!, current: currentStep!),
          ],
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
    return Row(
      children: List.generate(total, (i) {
        final isDone = i <= current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: isDone ? AppColors.primary : AppColors.grey200,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }),
    );
  }
}
