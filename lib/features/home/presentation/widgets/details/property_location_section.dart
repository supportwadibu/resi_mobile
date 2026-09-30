import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:resi_africa/shared/utils/launcher_helper.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

class PropertyLocationSection extends StatelessWidget {
  const PropertyLocationSection({
    super.key,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final propertyLocation = LatLng(latitude, longitude);

    return Section(
      title: 'Adresse',
      icon: LucideIcons.mapPin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(address, style: context.text.bodyMedium),
          const SizedBox(height: 12),
          DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(color: t.border),
              borderRadius: AppRadius.md,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.md,
              child: SizedBox(
                height: 180,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: propertyLocation,
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
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
                          point: propertyLocation,
                          width: 36,
                          height: 36,
                          alignment: Alignment.topCenter,
                          // Toujours noir : le marqueur est posé sur une carte
                          // aux couleurs fixes, qui ne suit pas le mode sombre.
                          child: Icon(
                            LucideIcons.mapPin,
                            color: t.overlay,
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
          const SizedBox(height: 12),
          AppButton(
            label: 'Ouvrir l\'itinéraire',
            icon: LucideIcons.navigation,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () => LauncherHelper.openNavigation(
              latitude: latitude,
              longitude: longitude,
            ),
          ),
        ],
      ),
    );
  }
}
