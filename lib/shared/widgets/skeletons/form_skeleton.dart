import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/loading_shimmer.dart';

/// Squelette d'un champ de formulaire : libellé court puis zone de saisie.
///
/// Les hauteurs reprennent celles d'`AppTextField` (label 13px + 8px d'écart
/// + champ de 48px) pour que le contenu ne décale rien en arrivant.
class FieldSkeleton extends StatelessWidget {
  const FieldSkeleton({super.key, this.labelWidth = 90});

  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoadingShimmer(height: 13, width: labelWidth, radius: 4),
        const SizedBox(height: 8),
        const LoadingShimmer(height: 48, radius: 12),
      ],
    );
  }
}

/// Squelette de l'étape « Informations personnelles » du dossier propriétaire.
///
/// Reproduit l'enchaînement réel : encart d'introduction, titre de section,
/// nom, puis le bloc de localisation pays → ville → adresse → téléphone.
class OwnerProfileFormSkeleton extends StatelessWidget {
  const OwnerProfileFormSkeleton({super.key, this.showIntro = false});

  final bool showIntro;

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        // Le formulaire réel défile : sans cela le squelette déborde sur les
        // écrans courts, là où le contenu qu'il annonce tient sans peine.
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showIntro) ...[
              const LoadingShimmer(height: 88, radius: 14),
              const SizedBox(height: 24),
            ],

            // Titre « Qui êtes-vous ? »
            const LoadingShimmer(height: 15, width: 150, radius: 4),
            const SizedBox(height: 20),
            const FieldSkeleton(labelWidth: 100),

            const SizedBox(height: 24),
            // Titre « Où résidez-vous ? »
            const LoadingShimmer(height: 15, width: 170, radius: 4),
            const SizedBox(height: 20),
            const FieldSkeleton(labelWidth: 45),
            const SizedBox(height: 16),
            const FieldSkeleton(labelWidth: 50),
            const SizedBox(height: 16),
            const FieldSkeleton(labelWidth: 70),

            const SizedBox(height: 24),
            const FieldSkeleton(labelWidth: 140),
          ],
        ),
      ),
    );
  }
}
