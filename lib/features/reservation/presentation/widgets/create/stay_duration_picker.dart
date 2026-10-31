import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

/// Sélecteur du nombre de jours pour un séjour complet (StayType.fullDay).
///
/// Permet au propriétaire ou gérant de définir directement le nombre de jours
/// facturés (ex: 1 jour pour une arrivée à 12h et un départ le lendemain à 15h)
/// sans que le système n'impose arbitrairement 2 jours.
///
/// C'est la seule commande de la durée : la sortie prévue s'en déduit et ne
/// se saisit pas. Le chiffre se tape directement pour un long séjour, que les
/// boutons ± obligeraient à atteindre jour par jour.
class StayDurationPicker extends StatefulWidget {
  const StayDurationPicker({
    required this.days,
    required this.onChanged,
    this.minDays = 1,
    this.maxDays,
    super.key,
  });

  final int days;
  final ValueChanged<int> onChanged;
  final int minDays;
  final int? maxDays;

  @override
  State<StayDurationPicker> createState() => _StayDurationPickerState();
}

class _StayDurationPickerState extends State<StayDurationPicker> {
  late final _controller = TextEditingController(text: '${widget.days}');
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(StayDurationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Seul un changement venu d'ailleurs (boutons ±) réécrit le champ : un
    // champ vidé en cours de frappe ne doit pas se remplir sous le doigt.
    if (widget.days != oldWidget.days &&
        int.tryParse(_controller.text) != widget.days) {
      _controller.text = '${widget.days}';
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// À l'entrée, le chiffre est sélectionné pour que la frappe le remplace ;
  /// à la sortie, une saisie vide ou hors bornes reprend la durée retenue.
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      _controller.text = '${widget.days}';
    }
  }

  bool _inBounds(int value) =>
      value >= widget.minDays &&
      (widget.maxDays == null || value <= widget.maxDays!);

  void _onTyped(String text) {
    final value = int.tryParse(text);
    if (value != null && _inBounds(value) && value != widget.days) {
      widget.onChanged(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final days = widget.days;
    final canDecrement = days > widget.minDays;
    final canIncrement = widget.maxDays == null || days < widget.maxDays!;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'booking_form.stay_duration'.tr(),
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'booking_form.days'.plural(days),
                  style: context.text.bodySmall!.copyWith(
                    color: t.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: LucideIcons.minus,
            label: 'booking_form.remove_day'.tr(),
            bordered: true,
            onPressed: canDecrement ? () => widget.onChanged(days - 1) : null,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              style: context.text.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: _onTyped,
              onTapOutside: (_) => _focusNode.unfocus(),
            ),
          ),
          const SizedBox(width: 8),
          AppIconButton(
            icon: LucideIcons.plus,
            label: 'booking_form.add_day'.tr(),
            bordered: true,
            onPressed: canIncrement ? () => widget.onChanged(days + 1) : null,
          ),
        ],
      ),
    );
  }
}
