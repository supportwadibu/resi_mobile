import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';

/// Couverture d'une fiche de bien, feuilletable au doigt.
///
/// Porte la galerie entière et non une seule image : le glissement latéral et
/// la bande de vignettes désignent la même photo, et l'écran hôte détient
/// l'index courant pour les garder synchronisées.
class PropertyCoverImage extends StatefulWidget {
  const PropertyCoverImage({
    super.key,
    required this.images,
    this.currentIndex = 0,
    this.onIndexChanged,
  });

  final List<String> images;

  /// Photo affichée, pilotée par l'écran hôte.
  final int currentIndex;

  /// Remonte le glissement, pour que les vignettes suivent.
  final ValueChanged<int>? onIndexChanged;

  @override
  State<PropertyCoverImage> createState() => _PropertyCoverImageState();
}

class _PropertyCoverImageState extends State<PropertyCoverImage> {
  late final PageController _controller = PageController(
    initialPage: widget.currentIndex,
  );

  @override
  void didUpdateWidget(PropertyCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // L'index a changé depuis les vignettes : la page suit. Le saut est animé
    // seulement si la page est déjà construite, `jumpToPage` sur un contrôleur
    // non attaché levant une exception.
    if (widget.currentIndex != oldWidget.currentIndex &&
        _controller.hasClients &&
        _controller.page?.round() != widget.currentIndex) {
      _controller.animateToPage(
        widget.currentIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final height = MediaQuery.of(context).size.height * 0.45;

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            const _CoverPlaceholder()
          else
            PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: widget.onIndexChanged,
              itemBuilder: (_, index) => _CoverImage(source: images[index]),
            ),

          // Dégradé posé au-dessus des photos : il assoit les contrôles de
          // l'écran, qui flottent sinon sur des visuels clairs.
          //
          // `IgnorePointer` : sans lui, ce calque capterait le glissement.
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),

          // Le compteur n'apparaît qu'à partir de deux photos : sur une seule,
          // il n'indiquerait rien.
          if (images.length > 1)
            Positioned(
              right: 16,
              bottom: 16,
              child: IgnorePointer(
                child: _PageDots(
                  count: images.length,
                  currentIndex: widget.currentIndex.clamp(0, images.length - 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Une photo de la galerie, distante ou empaquetée.
class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    if (source.isEmpty) return const _CoverPlaceholder();

    if (source.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _CoverLoading(),
        // Distinct du chargement : une photo injoignable doit montrer un
        // visuel de repli, jamais une animation qui tournerait sans fin.
        errorWidget: (_, _, _) => const _CoverPlaceholder(),
        fadeInDuration: const Duration(milliseconds: 200),
      );
    }

    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _CoverPlaceholder(),
    );
  }
}

/// Photo en cours de téléchargement.
///
/// Même aplat que le repli, pour que l'arrivée de l'image ne provoque aucun
/// saut de fond — seule l'animation le distingue.
class _CoverLoading extends StatelessWidget {
  const _CoverLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey200,
      child: const Center(child: AppLoader(size: 64)),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey200,
      child: Icon(Icons.home_outlined, size: 64, color: AppColors.grey400),
    );
  }
}

/// Position dans la galerie.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    // Au-delà de huit photos, les pastilles deviennent illisibles : le rang
    // s'écrit alors en toutes lettres.
    if (count > 8) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${currentIndex + 1}/$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == currentIndex ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == currentIndex
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
