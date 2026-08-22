import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';

/// Caractéristiques du bien : surface, pièces et ameublement.
///
/// Le décompte des pièces est exigé par l'API. La surface, elle, est
/// facultative : peu de propriétaires la connaissent au mètre près, et
/// l'exiger bloquait le dépôt d'annonces par ailleurs complètes.
class StepDetailsWidget extends StatefulWidget {
  const StepDetailsWidget({
    super.key,
    required this.surfaceArea,
    required this.bedrooms,
    required this.bathrooms,
    required this.livingRooms,
    required this.kitchens,
    required this.parkingSpaces,
    required this.furnishing,
    required this.onSurfaceChanged,
    required this.onBedroomsChanged,
    required this.onBathroomsChanged,
    required this.onLivingRoomsChanged,
    required this.onKitchensChanged,
    required this.onParkingChanged,
    required this.onFurnishingChanged,
  });

  final double? surfaceArea;
  final int bedrooms;
  final int bathrooms;
  final int livingRooms;
  final int kitchens;
  final int parkingSpaces;
  final Furnishing? furnishing;

  final ValueChanged<double?> onSurfaceChanged;
  final ValueChanged<int> onBedroomsChanged;
  final ValueChanged<int> onBathroomsChanged;
  final ValueChanged<int> onLivingRoomsChanged;
  final ValueChanged<int> onKitchensChanged;
  final ValueChanged<int> onParkingChanged;
  final ValueChanged<Furnishing?> onFurnishingChanged;

  @override
  State<StepDetailsWidget> createState() => _StepDetailsWidgetState();
}

class _StepDetailsWidgetState extends State<StepDetailsWidget> {
  late final TextEditingController _surfaceCtrl = TextEditingController(
    text: switch (widget.surfaceArea) {
      final surface? when surface > 0 => _trimZero(surface),
      _ => '',
    },
  );

  static String _trimZero(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  @override
  void dispose() {
    _surfaceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Décrivez votre bien',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 20),

        AppTextField(
          label: 'Surface (m²) — facultatif',
          hint: 'Ex: 85',
          controller: _surfaceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          prefixIcon: const Icon(Icons.straighten, size: 18),
          // Un champ vidé repasse à `null` : la clé sera omise de la requête,
          // là où un `0` aurait été refusé par le validateur.
          onChanged: (value) => widget.onSurfaceChanged(double.tryParse(value)),
        ),

        const SizedBox(height: 24),
        const Text(
          'Composition',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 12),

        _CounterRow(
          label: 'Chambres',
          icon: Icons.bed_outlined,
          value: widget.bedrooms,
          onChanged: widget.onBedroomsChanged,
        ),
        _CounterRow(
          label: 'Salles de bain',
          icon: Icons.bathtub_outlined,
          value: widget.bathrooms,
          onChanged: widget.onBathroomsChanged,
        ),
        _CounterRow(
          label: 'Salons',
          icon: Icons.weekend_outlined,
          value: widget.livingRooms,
          onChanged: widget.onLivingRoomsChanged,
        ),
        _CounterRow(
          label: 'Cuisines',
          icon: Icons.kitchen_outlined,
          value: widget.kitchens,
          onChanged: widget.onKitchensChanged,
        ),
        _CounterRow(
          label: 'Places de parking',
          icon: Icons.local_parking_outlined,
          value: widget.parkingSpaces,
          onChanged: widget.onParkingChanged,
        ),

        const SizedBox(height: 24),
        const Text(
          'Ameublement',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final option in Furnishing.values) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onFurnishingChanged(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.furnishing == option
                          ? AppColors.black
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: widget.furnishing == option
                            ? AppColors.black
                            : AppColors.grey200,
                        width: widget.furnishing == option ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      option.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.furnishing == option
                            ? AppColors.white
                            : AppColors.black,
                      ),
                    ),
                  ),
                ),
              ),
              if (option != Furnishing.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

/// Compteur à deux boutons, pour un décompte de pièces.
class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.black),
            ),
          ),
          _StepButton(
            icon: Icons.remove,
            // Un décompte négatif n'a pas de sens, et l'API le refuse.
            onTap: value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
          ),
          _StepButton(icon: Icons.add, onTap: () => onChanged(value + 1)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppColors.black : AppColors.grey400,
        ),
      ),
    );
  }
}
