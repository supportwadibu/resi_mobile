import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_picker_field.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/property_card.dart';

import '../../../../property/business_logic/property_cubit.dart';
import '../../../../property/business_logic/property_state.dart';
import '../../../../property/data/models/property_model.dart';

/// Choix du bien à réserver, parmi les annonces du propriétaire.
///
/// Remonte le tarif journalier avec l'identifiant : le montant attendu se
/// calcule alors sans attendre le serveur.
class PropertySelector extends StatelessWidget {
  const PropertySelector({
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final String? selectedId;
  final void Function(PropertyModel property) onSelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertyCubit, PropertyState>(
      builder: (context, state) => switch (state) {
        PropertyInitial() || PropertyLoading() => _SelectorShell(
          child: Row(
            children: [
              const AppLoader(size: 20),
              SizedBox(width: 12),
              Text(
                'booking_form.loading_residences'.tr(),
                style: context.mutedText,
              ),
            ],
          ),
        ),
        PropertyError(:final message) => _SelectorShell(
          child: Text(
            message,
            style: context.text.bodyMedium!.copyWith(
              color: context.tokens.danger,
            ),
          ),
        ),
        PropertyLoaded(items: final items) when items.isEmpty => _SelectorShell(
          child: Text(
            'booking_form.no_residence'.tr(),
            style: context.mutedText,
          ),
        ),
        PropertyLoaded(:final items) => AppPickerField(
          icon: AppSectionIcons.properties,
          value: _selected(items)?.title,
          placeholder: 'booking_form.choose_residence'.tr(),
          onTap: () => _pick(context, items),
        ),
      },
    );
  }

  /// Le bien retenu peut avoir été supprimé entre-temps : le champ revient
  /// alors à son invite plutôt que d'afficher un titre orphelin.
  PropertyModel? _selected(List<PropertyModel> items) {
    if (selectedId == null) return null;
    for (final p in items) {
      if (p.id == selectedId) return p;
    }
    return null;
  }

  Future<void> _pick(BuildContext context, List<PropertyModel> items) async {
    final chosen = await showAppSheet<PropertyModel>(
      context: context,
      builder: (_) =>
          _PropertyPickerSheet(items: items, selectedId: selectedId),
    );
    if (chosen != null) onSelected(chosen);
  }
}

/// Feuille de choix du bien : titre, ville et tarif journalier, pour
/// distinguer deux annonces au nom proche avant de valider.
class _PropertyPickerSheet extends StatefulWidget {
  const _PropertyPickerSheet({required this.items, required this.selectedId});

  final List<PropertyModel> items;
  final String? selectedId;

  @override
  State<_PropertyPickerSheet> createState() => _PropertyPickerSheetState();
}

class _PropertyPickerSheetState extends State<_PropertyPickerSheet> {
  /// En deçà, la liste tient à l'écran et un champ de recherche ne ferait
  /// que repousser les biens sous le pouce.
  static const _searchThreshold = 6;

  late List<PropertyModel> _filtered = widget.items;

  void _filter(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      _filtered = normalized.isEmpty
          ? widget.items
          : widget.items
                .where(
                  (p) =>
                      p.title.toLowerCase().contains(normalized) ||
                      p.address.city.toLowerCase().contains(normalized),
                )
                .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppSheet(
      title: 'booking_form.choose_residence'.tr(),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.items.length > _searchThreshold)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: _filter,
                style: context.text.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'common.search'.tr(),
                  prefixIcon: const Icon(LucideIcons.search, size: 16),
                ),
              ),
            ),
          if (_filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'common.no_results'.tr(),
                textAlign: TextAlign.center,
                style: context.mutedText,
              ),
            )
          else
            for (final property in _filtered)
              AppSheetAction(
                icon: AppSectionIcons.properties,
                label: property.title,
                description: [
                  if (property.address.city.isNotEmpty) property.address.city,
                  '${formatCompactPrice(property.pricing.dailyPrice)}'
                      '${'common.per_day'.tr()}',
                ].join(' · '),
                trailing: property.id == widget.selectedId
                    ? Icon(LucideIcons.check, size: 16, color: t.foreground)
                    : const SizedBox.shrink(),
                onTap: () => Navigator.of(context).pop(property),
              ),
        ],
      ),
    );
  }
}

class _SelectorShell extends StatelessWidget {
  const _SelectorShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      constraints: const BoxConstraints(minHeight: 46),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: context.tokens.background,
        borderRadius: AppRadius.md,
        border: Border.all(color: context.tokens.border),
      ),
      child: child,
    );
  }
}
