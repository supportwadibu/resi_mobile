import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../../core/router/role_guard.dart';
import '../../../../core/session/session_role.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/property_repository.dart';
import '../../../home/presentation/widgets/bottom_navigation/property_bottom_navigation_bar.dart';
import '../../../home/presentation/widgets/details/property_cover_image.dart';
import '../../../home/presentation/widgets/details/property_infos_header.dart';
import '../../../home/presentation/widgets/details/property_features.dart';
import '../../../home/presentation/widgets/details/property_description.dart';
import '../../../home/presentation/widgets/details/property_location_section.dart';
import '../../../home/presentation/widgets/details/property_pricing_details.dart';
import '../../../home/presentation/widgets/details/property_residence_section.dart';
import '../../../home/presentation/widgets/details/list_images_widget.dart';
import '../../../residence/data/repositories/residence_repository.dart';
import '../../../residence/presentation/widgets/attach_residence_sheet.dart';
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

  /// Fiche affichée, réévaluée après une modification ou un changement de
  /// visibilité.
  ///
  /// La route transporte un instantané du bien : sans état local, l'écran
  /// continuerait d'afficher la version d'avant l'enregistrement jusqu'au
  /// retour complet vers la liste.
  late PropertyModel _property = widget.property;

  /// Appel de publication en cours : la bascule est verrouillée le temps que
  /// le serveur réponde, deux appuis de suite s'annulant l'un l'autre.
  bool _isTogglingVisibility = false;

  PropertyModel get property => _property;

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
              SliverToBoxAdapter(
                child: PropertyCoverImage(
                  images: images,
                  currentIndex: _selectedImageIndex,
                  onIndexChanged: (index) =>
                      setState(() => _selectedImageIndex = index),
                ),
              ),

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

                      PropertyResidenceSection(
                        residenceId: property.residenceId,
                        unitLabel: property.unitLabel,
                        onAttachPressed: _attachResidence,
                      ),
                      const SizedBox(height: 24),

                      PropertyLocationSection(
                        address: _fullAddress(),
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

      bottomNavigationBar: PropertyBottomNavigationBar(
        onEditPressed: _openEditor,
        isPublished: property.isPublic,
        isTogglingVisibility: _isTogglingVisibility,
        onVisibilityChanged: _toggleVisibility,
        // Le rôle se lit sur la session, comme partout ailleurs dans le projet.
        canChangeVisibility: isGestureAllowed(
          sl<SessionRole>().value,
          'property_publish',
        ),
      ),
    );
  }

  Future<void> _openEditor() async {
    final updated = await context.router.push<PropertyModel>(
      AddPropertyRoute(property: property),
    );

    if (updated != null && mounted) setState(() => _property = updated);
  }

  /// Ouvre la feuille de rattachement à une résidence.
  ///
  /// La liste des résidences n'est pas chargée en amont : la feuille s'en
  /// charge, et s'ouvre donc dès l'appui. La charger ici laissait l'écran sans
  /// réaction le temps de la requête.
  Future<void> _attachResidence() async {
    final result = await AttachResidenceSheet.show(
      context,
      propertyTitle: property.title,
      currentResidenceId: property.residenceId,
      currentUnitLabel: property.unitLabel,
    );

    if (!mounted) return;

    if (result is AttachResidenceCreateRequested) {
      await context.router.push(AddResidenceRoute());
      // La feuille se réouvre sur la liste rechargée, résidence neuve comprise.
      if (mounted) await _attachResidence();
      return;
    }

    if (result == null) return;

    try {
      // La fiche renvoyée porte le rattachement, et l'adresse recopiée le cas
      // échéant : la reprendre évite d'afficher l'état d'avant l'appel.
      final updated = await sl<ResidenceRepository>().attachToResidence(
        property.id,
        residenceId: result.residenceId,
        unitLabel: result.unitLabel,
        copyAddress: result.copyAddress,
      );
      if (!mounted) return;
      setState(() => _property = updated);

      AppToast.success(
        result.residenceId == null
            ? 'Bien détaché de sa résidence'
            : 'Bien rattaché à la résidence',
        context: context,
      );
    } on AppFailure catch (f) {
      if (!mounted) return;
      AppToast.error(f.userMessage, context: context);
    }
  }

  Future<void> _toggleVisibility(bool publish) async {
    if (_isTogglingVisibility) return;
    setState(() => _isTogglingVisibility = true);

    try {
      final repository = sl<PropertyRepository>();
      final updated = publish
          ? await repository.publish(property.id)
          : await repository.unpublish(property.id);

      if (!mounted) return;
      setState(() => _property = updated);

      // Le retrait est un succès, signalé en avertissement : l'annonce cesse
      // d'être visible, et c'est la conséquence qui compte pour le lecteur.
      if (publish) {
        AppToast.success('L’annonce est en ligne.', context: context);
      } else {
        AppToast.warning(
          'L’annonce est retirée de la vitrine.',
          context: context,
        );
      }
    } on AppFailure catch (f) {
      if (!mounted) return;
      // Un 403 porte ici la marche à suivre — dossier d'identité à compléter :
      // le message du serveur est plus utile qu'un libellé générique.
      AppToast.error(f.userMessage, context: context);
    } finally {
      if (mounted) setState(() => _isTogglingVisibility = false);
    }
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
                        ? CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.contain,
                            // Le loader est clair : le plein écran est posé
                            // sur un fond noir.
                            placeholder: (_, _) =>
                                const AppLoader(size: 72, color: Colors.white),
                            errorWidget: (_, _, _) => const Icon(
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
