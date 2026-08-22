import 'package:flutter/material.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Projette une annonce sur le format attendu par [PropertyCard].
///
/// Partagée par l'accueil et l'onglet « Mes biens » : les deux doivent
/// abréger les montants et retenir la photo de couverture à l'identique.
PropertyData propertyCardData(PropertyModel property) {
  return PropertyData(
    name: property.title,
    location: property.address.city,
    price: formatCompactPrice(property.pricing.dailyPrice),
    // La notation n'est pas encore servie par l'API : une moyenne inventée
    // tromperait le propriétaire sur l'accueil réservé à son bien.
    rating: 0,
    image: property.images.isEmpty ? null : property.images.first,
  );
}

/// Abrège un montant en FCFA : 20000 → « 20k », 1500000 → « 1.5M ».
String formatCompactPrice(double amount) {
  if (amount >= 1000000) return '${_trimZero(amount / 1000000)}M';
  if (amount >= 1000) return '${_trimZero(amount / 1000)}k';
  return _trimZero(amount);
}

String _trimZero(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

class PropertyData {
  const PropertyData({
    required this.name,
    required this.location,
    required this.price,
    required this.rating,
    this.image,
  });

  final String name;
  final String location;
  final String price;
  final double rating;

  /// Visuel du bien : chemin d'asset local ou URL distante.
  ///
  /// `null` pour une annonce déposée sans photo — le cas est fréquent, la
  /// carte affiche alors un aplat neutre plutôt qu'une image cassée.
  final String? image;
}

/// Vignette d'un bien, quelle que soit la provenance de l'image.
///
/// Les annonces réelles portent des URLs Cloudinary tandis que les visuels de
/// démonstration sont empaquetés dans l'application : les deux passent par ce
/// widget, qui choisit le chargeur d'après le préfixe.
class _PropertyThumbnail extends StatelessWidget {
  const _PropertyThumbnail({required this.image, this.width, this.height});

  final String? image;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final source = image;

    if (source == null || source.isEmpty) {
      return _placeholder();
    }

    if (source.startsWith('http')) {
      return Image.network(
        source,
        width: width,
        height: height,
        fit: BoxFit.cover,
        // Une URL périmée ou un réseau coupé ne doit pas casser la liste.
        errorBuilder: (_, _, _) => _placeholder(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(),
      );
    }

    return Image.asset(
      source,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: AppColors.grey200,
    child: Icon(Icons.home_outlined, color: AppColors.grey400, size: 28),
  );
}

class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.data,
    this.onTap,
    this.onDelete,
    this.onShare,
    this.isListMode = false, // ← nouveau
  });

  final PropertyData data;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final bool isListMode;

  @override
  Widget build(BuildContext context) {
    return isListMode ? _buildList() : _buildGrid();
  }

  // ── Mode grille (layout actuel)
  Widget _buildGrid() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _PropertyThumbnail(
                      image: data.image,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  if (onDelete != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _CardIconButton(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.error,
                        onTap: onDelete!,
                      ),
                    ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: _PriceBadge(price: data.price),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _NameRow(name: data.name, onShare: onShare),
            const SizedBox(height: 4),
            _RatingRow(rating: data.rating, location: data.location),
          ],
        ),
      ),
    );
  }

  // ── Mode liste (horizontal)
  Widget _buildList() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Image fixe à gauche
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _PropertyThumbnail(
                    image: data.image,
                    width: 110,
                    height: 110,
                  ),
                ),
                if (onDelete != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _CardIconButton(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.error,
                      onTap: onDelete!,
                      size: 28,
                      iconSize: 14,
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _PriceBadge(price: data.price, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Infos à droite
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NameRow(name: data.name, onShare: onShare),
                  const SizedBox(height: 6),
                  _RatingRow(rating: data.rating, location: data.location),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets internes partagés
class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.price, this.fontSize = 15});
  final String price;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: price,
              style: TextStyle(
                color: AppColors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: '/jour',
              style: TextStyle(
                color: AppColors.white,
                fontSize: fontSize - 5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.name, this.onShare});
  final String name;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.black,
            ),
          ),
        ),
        if (onShare != null)
          _CardIconButton(
            icon: Icons.ios_share_rounded,
            color: AppColors.grey500,
            onTap: onShare!,
            size: 30,
            iconSize: 14,
          ),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.location});
  final double rating;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Un bien sans avis n'affiche pas d'étoile : un « 0 » se lirait comme
        // une très mauvaise note plutôt que comme une absence de note.
        if (rating > 0) ...[
          const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(width: 6),
        ],
        const Icon(Icons.location_on, size: 12, color: AppColors.grey400),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.grey500),
          ),
        ),
      ],
    );
  }
}

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 32,
    this.iconSize = 16,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: iconSize, color: color),
      ),
    );
  }
}
