import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';

/// Visionneuse plein écran d'une photo, distante ou empaquetée.
///
/// Fond `overlay`, noir dans les deux modes : une photo se regarde sur du
/// noir, et le fond de page blanc du mode sombre l'écraserait.
class ImageViewerUtils {
  static void showFullScreenImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImage(imagePath: imagePath);
        },
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String imagePath;

  const _FullScreenImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.overlay,
      body: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: imagePath.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: imagePath,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => AppLoader(color: t.onOverlay),
                      errorWidget: (_, _, _) => Icon(
                        LucideIcons.imageOff,
                        size: 40,
                        color: t.onOverlay.withValues(alpha: 0.6),
                      ),
                    )
                  : Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: Tooltip(
              message: 'Fermer',
              child: Material(
                color: t.overlay.withValues(alpha: 0.5),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: SizedBox.square(
                    dimension: 44,
                    child: Icon(LucideIcons.x, size: 22, color: t.onOverlay),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
