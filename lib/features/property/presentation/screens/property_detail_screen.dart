import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/widgets/bottom_navigation/property_bottom_navigation_bar.dart';
import '../../../home/presentation/widgets/details/property_cover_image.dart';
import '../../../home/presentation/widgets/details/property_infos_header.dart';
import '../../../home/presentation/widgets/details/property_features.dart';
import '../../../home/presentation/widgets/details/property_description.dart';
import '../../../home/presentation/widgets/details/property_location_section.dart';
import '../../../home/presentation/widgets/details/property_pricing_details.dart';
import '../../../home/presentation/widgets/details/list_images_widget.dart';
import '../../data/models/property_model.dart';

@RoutePage()
class PropertyDetailScreen extends StatefulWidget {
  const PropertyDetailScreen({super.key, required this.property});

  final PropertyModel property;

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  /// Vignette retenue par le lecteur : elle prend la place de la couverture.
  int _selectedImageIndex = 0;

  PropertyModel get property => widget.property;

  @override
  Widget build(BuildContext context) {
    final images = property.images;
    final cover = images.isEmpty
        ? null
        : images[_selectedImageIndex.clamp(0, images.length - 1)];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: PropertyCoverImage(image: cover)),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      ListImagesWidget(
                        images: images,
                        selectedIndex: _selectedImageIndex,
                        onTap: (index) =>
                            setState(() => _selectedImageIndex = index),
                      ),
                      if (images.isNotEmpty) const SizedBox(height: 24),

                      PropertyInfosHeader(
                        name: property.title,
                        location: property.address.city,
                        pricePerDay: property.pricing.dailyPrice,
                      ),
                      const SizedBox(height: 24),

                      PropertyFeatures(features: _features()),
                      const SizedBox(height: 24),

                      PropertyLocationSection(
                        address: _fullAddress(),
                        // Repli sur le centre d'Abidjan : la carte doit rester
                        // lisible même sans coordonnées relevées.
                        latitude: property.address.latitude ?? 5.3364,
                        longitude: property.address.longitude ?? -3.9772,
                      ),
                      const SizedBox(height: 24),

                      PropertyDescription(description: property.description),
                      if (property.description.trim().isNotEmpty)
                        const SizedBox(height: 24),

                      PropertyPricingDetails(
                        pricePerDay: property.pricing.dailyPrice,
                        priceTiers: property.pricing.priceTiers,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            top: 48,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleButton(
                  onTap: () => context.router.maybePop(),
                  child: const Icon(
                    Icons.chevron_left,
                    size: 24,
                    color: Colors.black,
                  ),
                ),
                if (cover != null)
                  _CircleButton(
                    onTap: () => _showFullScreenImage(context, cover),
                    child: const FaIcon(
                      FontAwesomeIcons.expand,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: PropertyBottomNavigationBar(onEditPressed: () {}),
    );
  }

  /// Caractéristiques marquantes du bien.
  ///
  /// Seules celles réellement présentes sont affichées : une salle de bain
  /// annoncée à zéro vaut mieux tue.
  List<PropertyFeature> _features() {
    final details = property.details;

    return [
      if (details.bedrooms > 0)
        PropertyFeature(
          icon: Icons.bed,
          label: details.bedrooms > 1 ? 'Chambres' : 'Chambre',
          count: details.bedrooms,
        ),
      if (details.bathrooms > 0)
        PropertyFeature(
          icon: Icons.bathtub,
          label: details.bathrooms > 1 ? 'Salles de bain' : 'Salle de bain',
          count: details.bathrooms,
        ),
      if (details.livingRooms > 0)
        PropertyFeature(
          icon: Icons.weekend,
          label: details.livingRooms > 1 ? 'Salons' : 'Salon',
          count: details.livingRooms,
        ),
      if (details.parkingSpaces > 0)
        PropertyFeature(
          icon: Icons.local_parking,
          label: 'Parking',
          count: details.parkingSpaces,
        ),
      if (property.amenities.contains(Amenity.wifi))
        PropertyFeature(icon: Icons.wifi, label: 'Wifi', count: 1),
      if (property.amenities.contains(Amenity.pool))
        PropertyFeature(icon: Icons.pool, label: 'Piscine', count: 1),
    ];
  }

  /// Rue et ville réunies, en ignorant la partie manquante.
  String _fullAddress() {
    final street = property.address.street.trim();
    final city = property.address.city.trim();

    return [
      if (street.isNotEmpty) street,
      if (city.isNotEmpty) city,
    ].join(', ');
  }

  void _showFullScreenImage(BuildContext context, String image) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: image.startsWith('http')
                        ? Image.network(
                            image,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: AppColors.grey400,
                            ),
                          )
                        : Image.asset(image, fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 48,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

/// Pastille translucide des actions posées sur la couverture.
class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: child,
      ),
    );
  }
}
