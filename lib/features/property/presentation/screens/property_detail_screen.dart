import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/utils/image_viewer_utils.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/status_badge.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../../core/router/role_guard.dart';
import '../../../../core/session/session_role.dart';
import '../../data/repositories/property_repository.dart';
import '../../../home/presentation/widgets/bottom_navigation/property_bottom_navigation_bar.dart';
import '../../../home/presentation/widgets/details/property_cover_image.dart';
import '../../../home/presentation/widgets/details/property_infos_header.dart';
import '../../../home/presentation/widgets/details/property_features.dart';
import '../../../home/presentation/widgets/details/property_description.dart';
import '../../../home/presentation/widgets/details/property_location_section.dart';
import '../../../home/presentation/widgets/details/property_pricing_details.dart';
import '../../../home/presentation/widgets/details/property_reservations_section.dart';
import '../../../home/presentation/widgets/details/property_residence_section.dart';
import '../../../home/presentation/widgets/details/list_images_widget.dart';
import '../../../residence/data/repositories/residence_repository.dart';
import '../../../residence/presentation/widgets/attach_residence_sheet.dart';
import '../../data/models/property_model.dart';
import 'package:resi_africa/shared/utils/ensure_online.dart';

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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                PropertyCoverImage(
                  images: images,
                  currentIndex: _selectedImageIndex,
                  onIndexChanged: (index) =>
                      setState(() => _selectedImageIndex = index),
                ),
                // Posés sur la photo : fond de surface et filet, pour rester
                // lisibles sur un visuel clair comme sur un visuel sombre.
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: LucideIcons.chevronLeft,
                        label: 'common.back'.tr(),
                        bordered: true,
                        onPressed: () => context.router.maybePop(),
                      ),
                      const Spacer(),
                      if (cover != null)
                        AppIconButton(
                          icon: LucideIcons.expand,
                          label: 'property_page.fullscreen'.tr(),
                          bordered: true,
                          onPressed: () => ImageViewerUtils.showFullScreenImage(
                            context,
                            cover,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList.list(
              children: [
                ListImagesWidget(
                  images: images,
                  selectedIndex: _selectedImageIndex,
                  onTap: (index) => setState(() => _selectedImageIndex = index),
                ),
                if (images.isNotEmpty) const SizedBox(height: 16),
                PropertyInfosHeader(
                  name: property.title,
                  location: property.address.city,
                  pricePerDay: property.pricing.dailyPrice,
                  status: StatusBadge(
                    label: property.status.label,
                    tone: StatusTones.property(property.status.code),
                  ),
                ),
                const SizedBox(height: 20),
                PropertyFeatures(features: _features()),
                const SizedBox(height: 12),
                PropertyResidenceSection(
                  residenceId: property.residenceId,
                  unitLabel: property.unitLabel,
                  onAttachPressed: _attachResidence,
                ),
                const SizedBox(height: 12),
                PropertyPricingDetails(
                  pricePerDay: property.pricing.dailyPrice,
                  priceTiers: property.pricing.priceTiers,
                ),
                const SizedBox(height: 12),
                PropertyLocationSection(
                  address: _fullAddress(),
                  latitude: property.address.latitude ?? 5.3364,
                  longitude: property.address.longitude ?? -3.9772,
                ),
                if (property.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  PropertyDescription(description: property.description),
                ],
                const SizedBox(height: 24),
                PropertyReservationsSection(propertyId: property.id),
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
    if (!await ensureOnline(context) || !mounted) return;
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
      if (!await ensureOnline(context) || !mounted) return;
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
            ? 'property_page.detached'.tr()
            : 'property_page.attached'.tr(),
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
        AppToast.success('property_page.published'.tr(), context: context);
      } else {
        AppToast.warning(
          'property_page.unpublished'.tr(),
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
          icon: LucideIcons.bed,
          label: 'property_page.bedrooms'.plural(details.bedrooms),
          count: details.bedrooms,
        ),
      if (details.bathrooms > 0)
        PropertyFeature(
          icon: LucideIcons.bath,
          label: 'property_page.bathrooms'.plural(details.bathrooms),
          count: details.bathrooms,
        ),
      if (details.livingRooms > 0)
        PropertyFeature(
          icon: LucideIcons.sofa,
          label: 'property_page.living_rooms'.plural(details.livingRooms),
          count: details.livingRooms,
        ),
      if (details.parkingSpaces > 0)
        PropertyFeature(
          icon: LucideIcons.squareParking,
          label: 'amenities.parking'.tr(),
          count: details.parkingSpaces,
        ),
      if (property.amenities.contains(Amenity.wifi))
        PropertyFeature(
          icon: LucideIcons.wifi,
          label: 'amenities.wifi'.tr(),
          count: 1,
          countable: false,
        ),
      if (property.amenities.contains(Amenity.pool))
        PropertyFeature(
          icon: LucideIcons.waves,
          label: 'amenities.pool'.tr(),
          count: 1,
          countable: false,
        ),
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
}
