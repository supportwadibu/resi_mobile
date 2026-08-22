import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _thumbnail(displayImages[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _thumbnail(String source) {
    if (source.startsWith('http')) {
      return Image.network(
        source,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(),
      );
    }

    return Image.asset(
      source,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    width: 60,
    height: 60,
    color: AppColors.grey200,
    child: Icon(Icons.image_outlined, size: 20, color: AppColors.grey400),
  );
}
