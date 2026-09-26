import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:image_picker/image_picker.dart';

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
        Text(
          'Ajoutez des photos de votre bien',
          style: context.text.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Minimum 3 photos recommandées · ${images.length} ajoutée(s)',
          style: context.text.bodySmall,
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
              return Material(
                color: context.tokens.background,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: context.tokens.border),
                ),
                child: InkWell(
                  onTap: () => _addImages(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.imagePlus,
                        size: 20,
                        color: context.tokens.muted,
                      ),
                      const SizedBox(height: 6),
                      Text('Ajouter', style: context.text.bodySmall),
                    ],
                  ),
                ),
              );
            }
            return Stack(
              children: [
                Positioned.fill(child: _Thumbnail(source: images[i])),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Tooltip(
                    message: 'Retirer',
                    child: Material(
                      color: context.tokens.surface,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: context.tokens.border),
                      ),
                      child: InkWell(
                        onTap: () => _removeImage(images, i),
                        child: SizedBox.square(
                          dimension: 28,
                          child: Icon(
                            LucideIcons.trash2,
                            size: 14,
                            color: context.tokens.danger,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (i == 0)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    // Voile fixe : l'étiquette est posée sur la photo.
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      color: context.tokens.overlay.withValues(alpha: 0.7),
                      child: Text(
                        'Couverture',
                        style: context.text.labelMedium!.copyWith(
                          color: context.tokens.onOverlay,
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
        placeholder: (_, _) => Container(color: context.tokens.background),
        errorWidget: (_, _, _) => Container(
          color: context.tokens.background,
          child: Icon(
            LucideIcons.imageOff,
            size: 20,
            color: context.tokens.muted,
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
