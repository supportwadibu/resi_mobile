import 'package:flutter/material.dart';

import '../../../../residence/data/models/residence_model.dart';

/// Choix de la résidence sur laquelle restreindre le relevé.
///
/// Rend `null` pour « tout le parc » — la valeur qui lève la restriction — et
/// n'est donc pas distinguable d'une annulation par sa seule valeur : la
/// feuille est refermée avec `pop(_Selection(...))` pour que l'appelant sache
/// qu'un choix a bien été fait.
class FinanceResidenceSheet extends StatelessWidget {
  const FinanceResidenceSheet({
    super.key,
    required this.residences,
    this.selectedId,
  });

  final List<ResidenceModel> residences;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Périmètre du relevé',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Fermer',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Restreint à une résidence, le relevé retient le revenu de ses '
              'logements, ses charges communes et celles de ses logements.',
              style: TextStyle(fontSize: 12, color: theme.hintColor),
            ),
          ),
          const SizedBox(height: 12),

          Flexible(
            // `RadioGroup` porte la sélection et la bascule : `groupValue` et
            // `onChanged` sur chaque tuile sont dépréciés depuis Flutter 3.32.
            child: RadioGroup<String?>(
              groupValue: selectedId,
              onChanged: (value) =>
                  Navigator.of(context).pop(FinanceScopeSelection(value)),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  RadioListTile<String?>(
                    value: null,
                    title: const Text('Tout le parc'),
                    subtitle: Text(
                      'Tous les biens et toutes les charges',
                      style: TextStyle(fontSize: 11, color: theme.hintColor),
                    ),
                  ),
                  if (residences.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Text(
                        'Aucune résidence enregistrée.',
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                    )
                  else
                    for (final residence in residences)
                      RadioListTile<String?>(
                        value: residence.id,
                        title: Text(residence.name),
                        subtitle: Text(
                          switch (residence.unitsCount) {
                            0 => 'Aucun logement',
                            1 => '1 logement',
                            _ => '${residence.unitsCount} logements',
                          },
                          style: TextStyle(fontSize: 11, color: theme.hintColor),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Choix confirmé dans la feuille.
///
/// Enveloppe la valeur parce que `null` est un choix légitime — « tout le
/// parc » — qu'un `pop(null)` d'annulation rendrait indiscernable.
class FinanceScopeSelection {
  const FinanceScopeSelection(this.residenceId);

  final String? residenceId;
}
