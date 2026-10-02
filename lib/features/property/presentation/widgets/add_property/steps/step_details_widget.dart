import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter/services.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';

/// Caractéristiques du bien : surface et pièces.
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
    required this.onSurfaceChanged,
    required this.onBedroomsChanged,
    required this.onBathroomsChanged,
    required this.onLivingRoomsChanged,
    required this.onKitchensChanged,
    required this.onParkingChanged,
  });

  final double? surfaceArea;
  final int bedrooms;
  final int bathrooms;
  final int livingRooms;
  final int kitchens;
  final int parkingSpaces;

  final ValueChanged<double?> onSurfaceChanged;
  final ValueChanged<int> onBedroomsChanged;
  final ValueChanged<int> onBathroomsChanged;
  final ValueChanged<int> onLivingRoomsChanged;
  final ValueChanged<int> onKitchensChanged;
  final ValueChanged<int> onParkingChanged;

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
        Text('property_form.describe'.tr(), style: context.text.titleMedium),
        const SizedBox(height: 20),

        AppTextField(
          label: 'property_form.surface_optional'.tr(),
          hint: 'property_form.surface_hint'.tr(),
          controller: _surfaceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          prefixIcon: const Icon(LucideIcons.ruler, size: 16),
          // Un champ vidé repasse à `null` : la clé sera omise de la requête,
          // là où un `0` aurait été refusé par le validateur.
          onChanged: (value) => widget.onSurfaceChanged(double.tryParse(value)),
        ),

        const SizedBox(height: 24),
        Text('property_form.composition'.tr(), style: context.text.titleMedium),
        const SizedBox(height: 12),

        _CounterRow(
          label: 'property_form.bedrooms'.tr(),
          icon: LucideIcons.bed,
          value: widget.bedrooms,
          onChanged: widget.onBedroomsChanged,
        ),
        _CounterRow(
          label: 'property_form.bathrooms'.tr(),
          icon: LucideIcons.bath,
          value: widget.bathrooms,
          onChanged: widget.onBathroomsChanged,
        ),
        _CounterRow(
          label: 'property_form.living_rooms'.tr(),
          icon: LucideIcons.sofa,
          value: widget.livingRooms,
          onChanged: widget.onLivingRoomsChanged,
        ),
        _CounterRow(
          label: 'property_form.kitchens'.tr(),
          icon: LucideIcons.refrigerator,
          value: widget.kitchens,
          onChanged: widget.onKitchensChanged,
        ),
        _CounterRow(
          label: 'property_form.parking_spaces'.tr(),
          icon: LucideIcons.squareParking,
          value: widget.parkingSpaces,
          onChanged: widget.onParkingChanged,
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
          Icon(icon, size: 16, color: context.tokens.muted),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: context.text.bodyMedium)),
          _StepButton(
            icon: LucideIcons.minus,
            // Un décompte négatif n'a pas de sens, et l'API le refuse.
            onTap: value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: context.text.titleMedium,
            ),
          ),
          _StepButton(
            icon: LucideIcons.plus,
            onTap: () => onChanged(value + 1),
          ),
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
    return AppIconButton(
      icon: icon,
      label: icon == LucideIcons.plus
          ? 'common.add'.tr()
          : 'property_form.remove'.tr(),
      bordered: true,
      onPressed: onTap,
    );
  }
}
