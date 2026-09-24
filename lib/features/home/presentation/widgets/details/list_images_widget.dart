import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';

/// Bandeau de vignettes d'une annonce.
///
/// Se replie entièrement lorsqu'aucune photo n'a été déposée : une rangée de
/// cadres vides n'apprendrait rien au lecteur.
class ListImagesWidget extends StatelessWidget {
  const ListImagesWidget({
    super.key,
    this.images = const [],
    this.onTap,
    this.selectedIndex,
  });

  final List<String> images;
  final void Function(int index)? onTap;

  /// Vignette actuellement montrée en couverture, mise en avant par un liseré.
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    // Le bandeau reste secondaire : au-delà de trois vignettes, la couverture
    // et l'affichage plein écran prennent le relais.
    final displayImages = images.take(3).toList();

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayImages.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;

          return GestureDetector(
            onTap: onTap == null ? null : () => onTap!(index),
            // La vignette retenue se détache par un liseré *et* par une marge
            // qui l'isole : la seule couleur de bordure se voyait mal sur les
            // photos sombres, qui la mangent.
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isSelected ? 3 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.black : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isSelected ? 11 : 14),
                child: _thumbnail(displayImages[index], isSelected ? 50 : 56),
              ),
            ),
          );
        },
      ),
    );
  }

  /// [size] : côté de l'image, réduit sur la vignette retenue pour que la
  /// marge qui l'isole ne déborde pas de la hauteur du bandeau.
  Widget _thumbnail(String source, double size) {
    if (source.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => _loading(size),
        // Distinct du chargement : une photo injoignable garde l'icône de
        // repli, là où l'animation tournerait sans fin.
        errorWidget: (_, _, _) => _placeholder(size),
      );
    }

    return Image.asset(
      source,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(size),
    );
  }

  /// Vignette en cours de téléchargement.
  ///
  /// Le loader est dimensionné sur la vignette : à sa taille par défaut, il
  /// déborderait largement d'un carré de 56 pixels.
  Widget _loading(double size) => Container(
    width: size,
    height: size,
    color: AppColors.grey200,
    child: Center(child: AppLoader(size: size * 0.6)),
  );

  Widget _placeholder(double size) => Container(
    width: size,
    height: size,
    color: AppColors.grey200,
    child: Icon(Icons.image_outlined, size: 20, color: AppColors.grey400),
  );
}
