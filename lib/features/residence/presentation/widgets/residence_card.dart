import 'package:flutter/material.dart';

import '../../data/models/residence_model.dart';

/// Une résidence dans la liste, avec son nombre de logements.
class ResidenceCard extends StatelessWidget {
  const ResidenceCard({
    super.key,
    required this.residence,
    this.onTap,
    this.onDelete,
  });

  final ResidenceModel residence;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.apartment_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      residence.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      residence.address.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                    const SizedBox(height: 8),
                    _UnitsBadge(count: residence.unitsCount),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Supprimer',
                  color: theme.colorScheme.error,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nombre de logements rattachés.
///
/// Une résidence vide est signalée en clair : elle n'est pas encore louable, et
/// c'est la seule chose à faire ensuite.
class _UnitsBadge extends StatelessWidget {
  const _UnitsBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = count == 0;

    final color = isEmpty ? theme.colorScheme.error : theme.colorScheme.primary;
    final label = switch (count) {
      0 => 'Aucun logement',
      1 => '1 logement',
      _ => '$count logements',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
