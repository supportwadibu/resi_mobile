import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

import '../../../data/models/property_deposit.dart';

/// Acompte du logement, montré seulement quand RESI laisse le propriétaire le
/// régler : accepté ou non, en pourcentage du séjour ou en montant fixe.
///
/// Le serveur relève l'acompte à la commission de RESI au besoin : le
/// propriétaire n'a pas à la connaître pour régler le sien.
class DepositCard extends StatefulWidget {
  const DepositCard({
    required this.deposit,
    required this.settings,
    required this.onChanged,
    super.key,
  });

  /// Réglage du logement ; `null` tant que le propriétaire n'y a pas touché.
  final PropertyDeposit? deposit;

  /// Règle de RESI, montrée en repli et reprise comme valeur de départ.
  final DepositSettings settings;
  final ValueChanged<PropertyDeposit> onChanged;

  @override
  State<DepositCard> createState() => _DepositCardState();
}

class _DepositCardState extends State<DepositCard> {
  late PropertyDeposit _current =
      widget.deposit ??
      PropertyDeposit(
        // Jamais réglé : la règle de RESI s'applique déjà, l'interrupteur le dit.
        enabled: true,
        type: widget.settings.type,
        value: widget.settings.value,
      );

  late final _value = TextEditingController(text: _format(_current.value));

  static String _format(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _emit(PropertyDeposit next) {
    setState(() => _current = next);
    widget.onChanged(next);
  }

  PropertyDeposit _with({bool? enabled, DepositType? type, double? value}) =>
      PropertyDeposit(
        enabled: enabled ?? _current.enabled,
        type: type ?? _current.type,
        value: value ?? _current.value,
      );

  String get _defaultLabel => widget.settings.type == DepositType.percent
      ? '${_format(widget.settings.value)} %'
      : '${_format(widget.settings.value)} F';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final percent = _current.type == DepositType.percent;

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
              const IconChip(icon: LucideIcons.wallet),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'property_deposit.enabled'.tr(),
                      style: context.text.titleSmall,
                    ),
                    Text(
                      'property_deposit.enabled_hint'.tr(),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Switch(
                value: _current.enabled,
                onChanged: (v) => _emit(_with(enabled: v)),
              ),
            ],
          ),
          if (_current.enabled) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                AppChoiceChip(
                  label: 'property_deposit.percent'.tr(),
                  selected: percent,
                  onTap: () => _emit(_with(type: DepositType.percent)),
                ),
                AppChoiceChip(
                  label: 'property_deposit.fixed'.tr(),
                  selected: !percent,
                  onTap: () => _emit(_with(type: DepositType.fixed)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppTextField(
              label:
                  (percent
                          ? 'property_deposit.value_percent'
                          : 'property_deposit.value_fixed')
                      .tr(),
              controller: _value,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) =>
                  _emit(_with(value: double.tryParse(v.trim()) ?? 0)),
            ),
            const SizedBox(height: 8),
            Text(
              'property_deposit.default_hint'.tr(args: [_defaultLabel]),
              style: context.text.bodySmall!.copyWith(color: t.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// L'acompte saisi est-il recevable ? Mêmes bornes que l'API.
bool isValidPropertyDeposit(PropertyDeposit? deposit) {
  if (deposit == null || !deposit.enabled) return true;
  if (deposit.value <= 0) return false;
  return deposit.type != DepositType.percent || deposit.value <= 99;
}
