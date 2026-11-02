import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
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
                const LoadingShimmer(height: 72, width: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LoadingShimmer(height: 17, width: 180),
                      const SizedBox(height: 8),
                      const LoadingShimmer(height: 13, width: 120),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bandeau de statut du dossier.
            const LoadingShimmer(height: 76),
            const SizedBox(height: 24),

            const LoadingShimmer(height: 15, width: 190),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: context.tokens.border),
        borderRadius: AppRadius.md,
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
                    const LoadingShimmer(height: 36, width: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LoadingShimmer(height: 11, width: 70),
                          const SizedBox(height: 6),
                          const LoadingShimmer(height: 13),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rowCount - 1)
                Divider(height: 1, color: context.tokens.border, indent: 64),
            ],
          );
        }),
      ),
    );
  }
}
