import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/features/property/data/services/location_service.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';

/// Localisation du bien.
///
/// La position de l'appareil est relevée dès l'ouverture de l'étape : dans la
/// quasi-totalité des cas le propriétaire dépose son annonce depuis le bien
/// lui-même, et la ville comme l'adresse s'en déduisent. Le refus de
/// l'autorisation n'est pas une impasse : la carte et les deux champs restent
/// saisissables à la main.
class StepLocationWidget extends StatefulWidget {
  const StepLocationWidget({
    super.key,
    required this.street,
    required this.city,
    required this.onStreetChanged,
    required this.onCityChanged,
    required this.onCoordinatesChanged,
  });

  final String street;
  final String city;
  final void Function(String) onStreetChanged;
  final void Function(String) onCityChanged;
  final void Function(double latitude, double longitude) onCoordinatesChanged;

  @override
  State<StepLocationWidget> createState() => _StepLocationWidgetState();
}

class _StepLocationWidgetState extends State<StepLocationWidget> {
  late final TextEditingController _addressCtrl = TextEditingController(
    text: widget.street,
  );
  late final TextEditingController _communeCtrl = TextEditingController(
    text: widget.city,
  );

  final _locationService = sl<LocationService>();
  final _mapController = MapController();

  /// Abidjan, en attendant un relevé : un centre plausible vaut mieux qu'un
  /// point au milieu de l'océan.
  LatLng _markerPos = const LatLng(5.3364, -3.9772);

  bool _isLocating = false;
  String? _locationNotice;

  @override
  void initState() {
    super.initState();
    // Seule une étape vierge déclenche le relevé : revenir sur l'étape ne doit
    // pas écraser une adresse déjà corrigée à la main.
    if (widget.street.isEmpty && widget.city.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _useCurrentPosition(),
      );
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _communeCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Relève la position puis pré-remplit ville et adresse.
  Future<void> _useCurrentPosition() async {
    setState(() {
      _isLocating = true;
      _locationNotice = null;
    });

    final position = await _locationService.currentPosition();

    if (!mounted) return;

    if (position == null) {
      setState(() {
        _isLocating = false;
        _locationNotice = 'property_form.location_unavailable'.tr();
      });
      return;
    }

    final point = LatLng(position.latitude, position.longitude);
    _applyPoint(point, moveMap: true);

    final address = await _locationService.resolveAddress(
      point.latitude,
      point.longitude,
    );

    if (!mounted) return;

    setState(() {
      _isLocating = false;
      // Les champs vides seulement sont complétés : une saisie manuelle
      // antérieure prime sur la déduction.
      if (address.city != null && _communeCtrl.text.trim().isEmpty) {
        _communeCtrl.text = address.city!;
        widget.onCityChanged(address.city!);
      }
      if (address.street != null && _addressCtrl.text.trim().isEmpty) {
        _addressCtrl.text = address.street!;
        widget.onStreetChanged(address.street!);
      }
      _locationNotice = address.isEmpty
          ? 'property_form.location_found'.tr()
          : null;
    });
  }

  /// Déplace le repère et remonte les coordonnées.
  void _applyPoint(LatLng point, {bool moveMap = false}) {
    setState(() => _markerPos = point);
    widget.onCoordinatesChanged(point.latitude, point.longitude);
    if (moveMap) _mapController.move(point, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CurrentPositionButton(
          isLoading: _isLocating,
          onPressed: _isLocating ? null : _useCurrentPosition,
        ),

        if (_locationNotice != null) ...[
          const SizedBox(height: 10),
          Text(_locationNotice!, style: context.text.bodySmall),
        ],

        const SizedBox(height: 20),

        AppTextField(
          label: 'fields.city'.tr(),
          hint: 'property_form.city_hint'.tr(),
          controller: _communeCtrl,
          prefixIcon: const Icon(LucideIcons.building, size: 16),
          onChanged: widget.onCityChanged,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'property_form.full_address'.tr(),
          hint: 'property_form.full_address_hint'.tr(),
          controller: _addressCtrl,
          prefixIcon: const Icon(LucideIcons.mapPin, size: 16),
          onChanged: widget.onStreetChanged,
        ),
        const SizedBox(height: 20),

        Text('property_form.map_position'.tr(), style: context.text.titleSmall),
        const SizedBox(height: 6),

        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            border: Border.all(color: context.tokens.border),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.md,
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _markerPos,
                  initialZoom: 13,
                  onTap: (_, point) => _applyPoint(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'ci.wadibu.resi_africa',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _markerPos,
                        width: 36,
                        height: 36,
                        alignment: Alignment.topCenter,
                        // Toujours noir : la carte garde ses couleurs claires
                        // quel que soit le mode.
                        child: Icon(
                          LucideIcons.mapPin,
                          color: context.tokens.overlay,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'property_form.map_hint'.tr(),
          style: context.text.bodySmall,
        ),
      ],
    );
  }
}

/// Bouton de relevé, avec son état d'attente.
class _CurrentPositionButton extends StatelessWidget {
  const _CurrentPositionButton({required this.isLoading, this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: isLoading
          ? 'property_form.locating'.tr()
          : 'property_form.use_my_location'.tr(),
      icon: LucideIcons.locateFixed,
      variant: AppButtonVariant.secondary,
      isLoading: isLoading,
      expand: true,
      onPressed: onPressed,
    );
  }
}
