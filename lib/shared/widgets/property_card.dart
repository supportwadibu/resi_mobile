import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';

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

class _PropertyThumbnail extends StatelessWidget {
  const _PropertyThumbnail({required this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    final source = image;

    if (source == null || source.isEmpty) {
      return const _Placeholder();
    }

    if (source.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: BoxFit.cover,
        placeholder: (_, _) => const _Placeholder(loading: true),
        // Une URL périmée ou un réseau coupé ne doit pas casser la liste, et
        // se distingue du chargement : l'icône de repli, pas une animation.
        errorWidget: (_, _, _) => const _Placeholder(),
      );
    }

    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _Placeholder(),
    );
  }
}

/// Aplat neutre d'une vignette sans photo, ou en cours de téléchargement.
class _Placeholder extends StatelessWidget {
  const _Placeholder({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.tokens.background,
      child: Center(
        child: loading
            ? const AppLoader(size: 24)
            : Icon(
                LucideIcons.bedDouble,
                color: context.tokens.muted,
                size: 24,
              ),
      ),
    );
  }
}

/// Carte d'une annonce : bloc bordé, photo à angles droits, prix sur un voile
/// noir posé sur la photo — `overlay` / `onOverlay`, identiques dans les deux
/// modes puisque le voile ne change pas.
class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
    required this.data,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.isListMode = false,
  });

  final PropertyData data;
  final VoidCallback? onTap;

  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  final bool isListMode;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.surface,
      shape: AppRadius.outlined(AppRadius.md, t.border),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: isListMode ? _buildList() : _buildGrid(),
      ),
    );
  }

  Widget _buildGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: _PropertyThumbnail(image: data.image)),
              if (onDelete != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _DeleteButton(onTap: onDelete!),
                ),
              Positioned(
                left: 8,
                bottom: 8,
                child: _PriceBadge(price: data.price),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NameRow(name: data.name),
              const SizedBox(height: 4),
              _RatingRow(rating: data.rating, location: data.location),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return Row(
      children: [
        SizedBox.square(
          dimension: 96,
          child: Stack(
            children: [
              Positioned.fill(child: _PropertyThumbnail(image: data.image)),
              if (onDelete != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _DeleteButton(onTap: onDelete!, size: 28),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _NameRow(name: data.name),
                const SizedBox(height: 4),
                _RatingRow(rating: data.rating, location: data.location),
                const SizedBox(height: 8),
                _PriceText(price: data.price),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.price});
  final String price;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: t.overlay.withValues(alpha: 0.7),
        borderRadius: AppRadius.pill,
      ),
      child: _PriceText(price: price, color: t.onOverlay),
    );
  }
}

class _PriceText extends StatelessWidget {
  const _PriceText({required this.price, this.color});
  final String price;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.tokens.foreground;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: price,
            style: context.text.amount.copyWith(color: color),
          ),
          TextSpan(
            text: ' /jour',
            style: context.text.bodySmall!.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.text.titleSmall!.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.location});
  final double rating;
  final String location;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        // Un bien sans avis n'affiche pas d'étoile : un « 0 » se lirait comme
        // une très mauvaise note plutôt que comme une absence de note.
        if (rating > 0) ...[
          Icon(LucideIcons.star, color: t.accentAmber, size: 12),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: context.text.bodySmall!.copyWith(
              color: t.foreground,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Icon(LucideIcons.mapPin, size: 12, color: t.muted),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap, this.size = 32});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: 'Supprimer',
      child: Material(
        color: t.surface,
        shape: AppRadius.outlined(AppRadius.sm, t.border),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Icon(LucideIcons.trash2, size: 14, color: t.danger),
          ),
        ),
      ),
    );
  }
}
