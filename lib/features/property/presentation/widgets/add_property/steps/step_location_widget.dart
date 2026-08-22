import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/features/property/data/services/location_service.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentPosition());
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
        _locationNotice =
            'Position indisponible. Placez le repère sur la carte ou '
            'saisissez l’adresse.';
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
          ? 'Position relevée. Complétez l’adresse à la main.'
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
          Text(
            _locationNotice!,
            style: const TextStyle(fontSize: 11, color: AppColors.grey500),
          ),
        ],

        const SizedBox(height: 20),

        AppTextField(
          label: 'Ville',
          hint: 'Ex: Abidjan, Bouaké, Yamoussoukro...',
          controller: _communeCtrl,
          prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
          onChanged: widget.onCityChanged,
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Adresse complète',
          hint: 'Ex: Rue des Jardins, Cocody...',
          controller: _addressCtrl,
          prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
          onChanged: widget.onStreetChanged,
        ),
        const SizedBox(height: 20),

        const Text(
          'Position sur la carte',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 10),

        ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ci.wadibu.resi_africa',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _markerPos,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Appuyez sur la carte pour ajuster la position de votre bien',
          style: TextStyle(fontSize: 11, color: AppColors.grey500),
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location, size: 18),
        label: Text(
          isLoading ? 'Localisation en cours...' : 'Utiliser ma position',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.grey200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
