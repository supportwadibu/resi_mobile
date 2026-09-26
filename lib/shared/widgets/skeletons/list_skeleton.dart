import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/loading_shimmer.dart';

/// Squelette d'une carte de bien en mode liste.
///
/// Les dimensions reprennent celles de `PropertyCard` en `isListMode` :
/// vignette de 96, carte bordée. Le contenu réel se substitue au squelette
/// sans décalage. Pas de fond : `ShimmerEffect` teinte tout ce qui est
/// peint, et la carte entière clignoterait.
class PropertyCardSkeleton extends StatelessWidget {
  const PropertyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: context.tokens.border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LoadingShimmer(height: 96, width: 96),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              // Aligné sur la vignette : `Spacer` exigerait une hauteur bornée,
              // que la carte ne reçoit pas dans une liste à défilement.
              height: 96,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du bien
                    const LoadingShimmer(height: 15),
                    const SizedBox(height: 8),
                    // Localisation, plus courte que le nom
                    const LoadingShimmer(height: 12, width: 130),
                    const Spacer(),
                    // Note et prix
                    Row(
                      children: const [
                        LoadingShimmer(height: 12, width: 60),
                        Spacer(),
                        LoadingShimmer(height: 20, width: 70),
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
        itemBuilder: (_, _) => LoadingShimmer(height: itemHeight),
      ),
    );
  }
}
