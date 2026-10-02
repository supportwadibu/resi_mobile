import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';

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
        PropertyLoaded(:final items) => _SelectorShell(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _validSelection(items),
              isExpanded: true,
              hint: Text(
                'booking_form.choose_residence'.tr(),
                style: context.mutedText,
              ),
              items: items
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        p.title,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (id) {
                if (id == null) return;
                onSelected(items.firstWhere((p) => p.id == id));
              },
            ),
          ),
        ),
      },
    );
  }

  /// `DropdownButton` lève si la valeur ne figure pas dans ses éléments — ce
  /// qui arrive quand le bien retenu a été supprimé entre-temps.
  String? _validSelection(List<PropertyModel> items) {
    if (selectedId == null) return null;
    return items.any((p) => p.id == selectedId) ? selectedId : null;
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
