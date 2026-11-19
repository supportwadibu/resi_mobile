import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/resi_tokens.dart';
import 'loading_shimmer.dart';

/// Indicateur d'attente : des blocs gris balayés par le reflet du shimmer,
/// jamais un anneau qui tourne. Une petite taille (bouton, champ, pied de
/// liste) donne une barre en pilule ; la taille par défaut, trois lignes de
/// texte à venir.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 32, this.color});

  final double size;

  /// Gardé pour les appelants posés sur une photo : le reflet du shimmer
  /// remplace la teinte, si bien qu'elle n'a plus d'effet.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (size < 32) {
      return SizedBox(
        height: size,
        child: Center(
          child: ShimmerEffect(
            child: LoadingShimmer(
              width: size * 2.4,
              height: (size * 0.4).clamp(6.0, 12.0),
              radius: AppRadius.pill,
            ),
          ),
        ),
      );
    }
    return const Center(
      child: ShimmerEffect(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingShimmer(width: 180, height: 14),
            SizedBox(height: 10),
            LoadingShimmer(width: 240, height: 14),
            SizedBox(height: 10),
            LoadingShimmer(width: 140, height: 14),
          ],
        ),
      ),
    );
  }
}

/// Écran d'attente plein cadre : le squelette d'une page des maquettes —
/// en-tête, grand titre, carte de tête, tuiles et lignes —, pour que le
/// contenu arrive à sa place sans que la mise en page saute.
class AppLoaderScreen extends StatelessWidget {
  const AppLoaderScreen({super.key, this.backgroundColor});

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? context.tokens.background,
      body: const SafeArea(child: PageSkeleton()),
    );
  }
}

/// Squelette de page, réutilisable sous un en-tête déjà affiché.
class PageSkeleton extends StatelessWidget {
  const PageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerEffect(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LoadingShimmer(width: 44, height: 44, radius: AppRadius.pill),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingShimmer(width: 80, height: 10),
                      SizedBox(height: 8),
                      LoadingShimmer(width: 130, height: 14),
                    ],
                  ),
                ),
                LoadingShimmer(width: 44, height: 44, radius: AppRadius.pill),
              ],
            ),
            SizedBox(height: 26),
            LoadingShimmer(width: 230, height: 30),
            SizedBox(height: 10),
            LoadingShimmer(width: 170, height: 30),
            SizedBox(height: 22),
            Row(
              children: [
                LoadingShimmer(width: 90, height: 40, radius: AppRadius.pill),
                SizedBox(width: 8),
                LoadingShimmer(width: 110, height: 40, radius: AppRadius.pill),
                SizedBox(width: 8),
                LoadingShimmer(width: 90, height: 40, radius: AppRadius.pill),
              ],
            ),
            SizedBox(height: 18),
            LoadingShimmer(height: 150, radius: AppRadius.lg),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LoadingShimmer(height: 122, radius: AppRadius.lg),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: LoadingShimmer(height: 122, radius: AppRadius.lg),
                ),
              ],
            ),
            SizedBox(height: 10),
            LoadingShimmer(height: 72, radius: AppRadius.lg),
            SizedBox(height: 8),
            LoadingShimmer(height: 72, radius: AppRadius.lg),
          ],
        ),
      ),
    );
  }
}
