import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/loading_shimmer.dart';

/// Squelette d'une carte de bien en mode liste.
///
/// Les dimensions reprennent celles de `PropertyCard` en `isListMode` :
/// vignette 110×110 arrondie à 14, carte à 8 de marge intérieure et 20 de
/// rayon. Le contenu réel se substitue au squelette sans décalage.
class PropertyCardSkeleton extends StatelessWidget {
  const PropertyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingShimmer(height: 110, width: 110, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              // Aligné sur la vignette : `Spacer` exigerait une hauteur bornée,
              // que la carte ne reçoit pas dans une liste à défilement.
              height: 110,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du bien
                    const LoadingShimmer(height: 15, radius: 4),
                    const SizedBox(height: 8),
                    // Localisation, plus courte que le nom
                    const LoadingShimmer(height: 12, width: 130, radius: 4),
                    const Spacer(),
                    // Note et prix
                    Row(
                      children: const [
                        LoadingShimmer(height: 12, width: 60, radius: 4),
                        Spacer(),
                        LoadingShimmer(height: 20, width: 70, radius: 6),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Liste de squelettes de cartes, à afficher pendant le chargement.
class PropertyListSkeleton extends StatelessWidget {
  const PropertyListSkeleton({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(16),
    this.shrinkWrap = true,
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  /// La liste se dimensionne sur son contenu.
  ///
  /// Vrai par défaut : le squelette compte un nombre fixe d'éléments et se
  /// retrouve souvent dans une colonne défilante, où une hauteur non bornée
  /// ferait échouer la mise en page. Le passer à `false` n'a d'intérêt que pour
  /// remplir une zone déjà bornée, sur une liste longue.
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView.separated(
        shrinkWrap: shrinkWrap,
        // Le squelette n'est pas manipulable : le laisser défiler laisserait
        // croire à du contenu réel.
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => const PropertyCardSkeleton(),
      ),
    );
  }
}

/// Squelette générique de liste, pour les écrans dont la carte n'a pas encore
/// de forme arrêtée.
class SimpleListSkeleton extends StatelessWidget {
  const SimpleListSkeleton({
    super.key,
    this.itemCount = 8,
    this.itemHeight = 72,
    this.shrinkWrap = true,
  });

  final int itemCount;
  final double itemHeight;

  /// Voir [PropertyListSkeleton.shrinkWrap].
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView.separated(
        shrinkWrap: shrinkWrap,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => LoadingShimmer(height: itemHeight, radius: 14),
      ),
    );
  }
}
