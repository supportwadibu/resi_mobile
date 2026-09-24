import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

/// Photos de l'annonce.
///
/// [images] mêle deux natures d'entrée, indistinctes à l'écran : des chemins
/// de fichiers de l'appareil, déposés au moment de l'envoi, et — en
/// modification — les URLs des photos déjà hébergées. Seules les premières
/// sont envoyées ; l'ordre de la liste, lui, fait foi des deux côtés, la
/// première photo servant de couverture.
class StepImagesWidget extends StatelessWidget {
  const StepImagesWidget({
    super.key,
    required this.images,
    required this.onChanged,
    this.maxImages = 15,
  });

  final List<String> images;
  final void Function(List<String>) onChanged;

  /// Plafond aligné sur celui du serveur, qui refuse au-delà.
  final int maxImages;

  Future<void> _addImages(BuildContext context) async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;

    final remaining = maxImages - images.length;
    if (remaining <= 0) return;

    final updated = List<String>.from(images)
      ..addAll(picked.take(remaining).map((file) => file.path));
    onChanged(updated);

    if (picked.length > remaining && context.mounted) {
      AppToast.warning('$maxImages photos au maximum.', context: context);
    }
  }

  void _removeImage(List<String> current, int index) {
    final updated = List<String>.from(current)..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ajoutez des photos de votre bien',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Minimum 3 photos recommandées · ${images.length} ajoutée(s)',
          style: TextStyle(fontSize: 12, color: AppColors.grey500),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: images.length + 1,
          itemBuilder: (_, i) {
            if (i == images.length) {
              return GestureDetector(
                onTap: () => _addImages(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.grey200,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.plus,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ajouter',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _Thumbnail(source: images[i]),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _removeImage(images, i),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                if (i == 0)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Principale',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Vignette d'une photo, qu'elle soit déjà hébergée ou encore sur l'appareil.
///
/// Les deux cohabitent dans la grille dès qu'on modifie une annonce : une URL
/// passée à `Image.file` afficherait une tuile cassée.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.source});

  final String source;

  bool get _isHosted =>
      source.startsWith('http://') || source.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isHosted) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, _) => Container(color: AppColors.surface),
        errorWidget: (_, _, _) => Container(
          color: AppColors.surface,
          child: const Icon(
            Icons.broken_image_outlined,
            size: 20,
            color: AppColors.grey500,
          ),
        ),
      );
    }

    return Image.file(
      File(source),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
