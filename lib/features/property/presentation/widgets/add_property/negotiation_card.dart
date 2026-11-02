import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/utils/currency_formatter.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

import '../../../data/models/property_model.dart';

/// Négociation du logement : interrupteur, puis les paliers de prix par jour
/// que le client découvre un à un en appuyant sur « Négocier ».
class NegotiationCard extends StatefulWidget {
  const NegotiationCard({
    required this.negotiation,
    required this.dailyPrice,
    required this.onChanged,
    super.key,
  });

  final PropertyNegotiation negotiation;

  /// Prix normal : chaque palier doit rester en dessous.
  final double dailyPrice;
  final ValueChanged<PropertyNegotiation> onChanged;

  @override
  State<NegotiationCard> createState() => _NegotiationCardState();
}

class _NegotiationCardState extends State<NegotiationCard> {
  // Un contrôleur par palier, gardé entre deux reconstructions : la saisie
  // en cours ne doit pas sauter quand le parent se redessine.
  late final List<TextEditingController> _controllers = [
    for (final price in widget.negotiation.prices)
      TextEditingController(text: '$price'),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<int> get _prices => [
    for (final c in _controllers) int.tryParse(c.text.trim()) ?? 0,
  ];

  void _emit({bool? enabled}) {
    widget.onChanged(
      PropertyNegotiation(
        enabled: enabled ?? widget.negotiation.enabled,
        prices: _prices,
      ),
    );
  }

  void _toggle(bool enabled) {
    // Activer sans palier propose d'emblée un premier palier à remplir.
    if (enabled && _controllers.isEmpty) _addStep(notify: false);
    _emit(enabled: enabled);
  }

  void _addStep({bool notify = true}) {
    if (_controllers.length >= PropertyNegotiation.maxSteps) return;
    // Proposé 10 % sous le palier précédent, ou sous le prix normal : le
    // propriétaire corrige, il ne part pas d'une case vide.
    final previous = _prices.isEmpty
        ? widget.dailyPrice
        : _prices.last.toDouble();
    final suggested = previous > 0 ? (previous * 0.9).round() : 0;
    setState(
      () => _controllers.add(
        TextEditingController(text: suggested > 0 ? '$suggested' : ''),
      ),
    );
    if (notify) _emit();
  }

  void _removeStep(int index) {
    setState(() => _controllers.removeAt(index).dispose());
    _emit(enabled: _controllers.isEmpty ? false : null);
  }

  /// Message d'un palier hors des bornes, `null` s'il est valable.
  String? _errorFor(int index) {
    final prices = _prices;
    final price = prices[index];
    if (price <= 0) return 'property_form.negotiation_step_required'.tr();
    final ceiling = index == 0 ? widget.dailyPrice : prices[index - 1];
    if (ceiling > 0 && price >= ceiling) {
      return index == 0
          ? 'property_form.negotiation_below_price'.tr()
          : 'property_form.negotiation_below_previous'.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = widget.negotiation.enabled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const IconChip(icon: LucideIcons.handshake),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'property_form.negotiation'.tr(),
                      style: context.text.titleSmall,
                    ),
                    Text(
                      'property_form.negotiation_hint'.tr(),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: _toggle),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 16),
            for (final (index, controller) in _controllers.indexed) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'property_form.negotiation_step'.tr(
                        args: ['${index + 1}'],
                      ),
                      hint: 'property_form.price_hint'.tr(),
                      controller: controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      prefixIcon: const Icon(LucideIcons.banknote, size: 18),
                      onChanged: (_) => setState(_emit),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 26),
                    child: AppIconButton(
                      icon: LucideIcons.trash2,
                      label: 'property_form.negotiation_remove'.tr(),
                      danger: true,
                      onPressed: () => _removeStep(index),
                    ),
                  ),
                ],
              ),
              if (_errorFor(index) case final error?)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    error,
                    style: context.text.bodySmall?.copyWith(
                      color: t.accent(AppAccent.red),
                    ),
                  ),
                )
              else if (widget.dailyPrice > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'property_form.negotiation_saving'.tr(
                      args: [
                        CurrencyFormatter.fcfa(
                          widget.dailyPrice - _prices[index],
                        ),
                      ],
                    ),
                    style: context.text.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
            ],
            AppButton(
              label: 'property_form.negotiation_add'.tr(),
              icon: LucideIcons.plus,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.sm,
              onPressed: _controllers.length < PropertyNegotiation.maxSteps
                  ? _addStep
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              'property_form.negotiation_rule'.tr(),
              style: context.text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
