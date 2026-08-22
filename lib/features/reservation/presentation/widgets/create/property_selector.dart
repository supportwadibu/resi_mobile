import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

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
        PropertyInitial() || PropertyLoading() => const _SelectorShell(
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text(
                'Chargement des résidences…',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        PropertyError(:final message) => _SelectorShell(
          child: Text(
            message,
            style: const TextStyle(fontSize: 13, color: AppColors.error),
          ),
        ),
        PropertyLoaded(items: final items) when items.isEmpty =>
          const _SelectorShell(
            child: Text(
              'Aucune résidence enregistrée.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        PropertyLoaded(:final items) => _SelectorShell(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _validSelection(items),
              isExpanded: true,
              hint: const Text(
                'Choisir une résidence',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              items: items
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        p.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      constraints: const BoxConstraints(minHeight: 52),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}
