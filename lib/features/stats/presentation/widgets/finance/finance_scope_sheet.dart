import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_option_tile.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';

import '../../../../property/data/models/property_model.dart';
import '../../../../residence/data/models/residence_model.dart';
import '../../../data/models/finance/finance_scope.dart';

/// Choix du périmètre du relevé : tout le parc, une résidence entière ou l'un
/// de ses logements, et les logements indépendants.
///
/// Rend le périmètre retenu, ou `null` si la feuille est fermée sans choix —
/// « tout le parc » étant un [FinanceScope] à part entière, les deux ne se
/// confondent pas.
class FinanceScopeSheet extends StatelessWidget {
  const FinanceScopeSheet({
    super.key,
    required this.residences,
    required this.properties,
    required this.selected,
  });

  final List<ResidenceModel> residences;
  final List<PropertyModel> properties;
  final FinanceScope selected;

  static Future<FinanceScope?> show(
    BuildContext context, {
    required List<ResidenceModel> residences,
    required List<PropertyModel> properties,
    required FinanceScope selected,
  }) {
    return showAppSheet<FinanceScope>(
      context: context,
      builder: (_) => FinanceScopeSheet(
        residences: residences,
        properties: properties,
        selected: selected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void select(FinanceScope scope) => Navigator.of(context).pop(scope);

    final residenceIds = {for (final r in residences) r.id};
    final unitsByResidence = <String, List<PropertyModel>>{};
    final standalone = <PropertyModel>[];

    for (final property in properties) {
      final residenceId = property.residenceId;
      // Un logement rattaché à une résidence absente de la liste reste
      // sélectionnable parmi les indépendants : le ranger sous une résidence
      // introuvable le ferait disparaître du choix.
      if (residenceId != null && residenceIds.contains(residenceId)) {
        unitsByResidence.putIfAbsent(residenceId, () => []).add(property);
      } else {
        standalone.add(property);
      }
    }

    return AppSheet(
      title: 'finance_page.scope_title'.tr(),
      description: 'finance_page.scope_body'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // « Tout le parc » en tête, et non en fin de liste : c'est le choix
          // qui lève la restriction, on doit le trouver sans parcourir les
          // biens.
          AppOptionTile(
            title: 'finance_page.whole_portfolio'.tr(),
            description: 'finance_page.whole_portfolio_hint'.tr(),
            icon: LucideIcons.building,
            selected: selected.isPortfolio,
            onTap: () => select(const FinanceScope.portfolio()),
          ),
          const SizedBox(height: 8),
          // Parc vide : « Tout le parc » reste proposé au-dessus, le relevé
          // est consultable, seule la restriction est impossible.
          if (residences.isEmpty && properties.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'finance_page.no_property'.tr(),
                style: context.text.bodySmall,
              ),
            ),
          for (final residence in residences) ...[
            _ResidenceOption(
              residence: residence,
              selected:
                  selected ==
                  FinanceScope.residence(
                    id: residence.id,
                    name: residence.name,
                  ),
              onTap: select,
            ),
            const SizedBox(height: 8),
            for (final unit in unitsByResidence[residence.id] ?? const [])
              // En retrait sous leur résidence : on lit d'un coup d'œil que
              // choisir la résidence les englobe tous.
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 8),
                child: _PropertyOption(
                  property: unit,
                  name: _unitName(unit),
                  description: unit.propertyType.label,
                  selected: selected,
                  onTap: select,
                ),
              ),
          ],
          if (standalone.isNotEmpty) ...[
            if (residences.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'finance_page.standalone_properties'.tr(),
                style: context.text.titleSmall,
              ),
              const SizedBox(height: 8),
            ],
            for (final property in standalone) ...[
              _PropertyOption(
                property: property,
                name: property.title,
                description:
                    '${property.propertyType.label} · ${property.address.city}',
                selected: selected,
                onTap: select,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }

  /// « Studio 1 » plutôt que le titre de l'annonce : sous sa résidence, c'est
  /// le nom de l'unité qui la distingue de ses voisines.
  static String _unitName(PropertyModel property) {
    final unit = property.unitLabel?.trim();
    return unit == null || unit.isEmpty ? property.title : unit;
  }
}

class _ResidenceOption extends StatelessWidget {
  const _ResidenceOption({
    required this.residence,
    required this.selected,
    required this.onTap,
  });

  final ResidenceModel residence;
  final bool selected;
  final ValueChanged<FinanceScope> onTap;

  @override
  Widget build(BuildContext context) {
    return AppOptionTile(
      title: residence.name,
      description: switch (residence.unitsCount) {
        0 => residence.address.city,
        final count => 'residence.city_units'.plural(
          count,
          namedArgs: {'city': residence.address.city, 'count': '$count'},
        ),
      },
      icon: AppSectionIcons.residences,
      selected: selected,
      onTap: () =>
          onTap(FinanceScope.residence(id: residence.id, name: residence.name)),
    );
  }
}

class _PropertyOption extends StatelessWidget {
  const _PropertyOption({
    required this.property,
    required this.name,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final PropertyModel property;

  /// Nom porté par le bouton du périmètre une fois le logement retenu.
  final String name;
  final String description;
  final FinanceScope selected;
  final ValueChanged<FinanceScope> onTap;

  @override
  Widget build(BuildContext context) {
    final scope = FinanceScope.property(id: property.id, name: name);

    return AppOptionTile(
      title: name,
      description: description,
      icon: AppSectionIcons.properties,
      selected: selected == scope,
      onTap: () => onTap(scope),
    );
  }
}
