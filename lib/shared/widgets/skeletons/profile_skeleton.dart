import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/loading_shimmer.dart';

/// Squelette de l'onglet profil.
///
/// Reprend l'enchaînement réel — en-tête avatar, sections d'informations et
/// de réglages — pour que l'arrivée des données ne redessine pas l'écran.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key, this.infoCount = 5});

  /// Nombre de lignes d'informations attendues.
  final int infoCount;

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : avatar carré 72 + nom et sous-titre.
            Row(
              children: [
                const LoadingShimmer(height: 72, width: 72, radius: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LoadingShimmer(height: 17, width: 180, radius: 4),
                      const SizedBox(height: 8),
                      const LoadingShimmer(height: 13, width: 120, radius: 4),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bandeau de statut du dossier.
            const LoadingShimmer(height: 76, radius: 20),
            const SizedBox(height: 24),

            const LoadingShimmer(height: 15, width: 190, radius: 4),
            const SizedBox(height: 12),
            _GroupSkeleton(rowCount: infoCount),
          ],
        ),
      ),
    );
  }
}

/// Bloc encadré de lignes, à la forme d'`_InfoGroup`.
class _GroupSkeleton extends StatelessWidget {
  const _GroupSkeleton({required this.rowCount});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: List.generate(rowCount, (i) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const LoadingShimmer(height: 36, width: 36, radius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LoadingShimmer(height: 11, width: 70, radius: 4),
                          const SizedBox(height: 6),
                          const LoadingShimmer(height: 13, radius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rowCount - 1)
                const Divider(height: 1, color: AppColors.grey200, indent: 64),
            ],
          );
        }),
      ),
    );
  }
}
