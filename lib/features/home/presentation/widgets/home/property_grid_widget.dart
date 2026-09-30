import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/features/property/business_logic/property_cubit.dart';
import 'package:resi_africa/features/property/business_logic/property_state.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/property_card.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';

/// Aperçu des biens du propriétaire sur l'accueil.
///
/// Consomme le `PropertyCubit` fourni par l'écran hôte : l'accueil et l'onglet
/// « Mes biens » lisent ainsi la même liste, chargée une seule fois.
class PropertyGridWidget extends StatelessWidget {
  const PropertyGridWidget({super.key, this.maxItems = 4});

  /// Nombre de biens affichés en aperçu.
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertyCubit, PropertyState>(
      builder: (context, state) => switch (state) {
        PropertyInitial() || PropertyLoading() => const PropertyListSkeleton(
          itemCount: 2,
          padding: EdgeInsets.zero,
        ),
        PropertyError(:final message) => _Notice(message: message),
        PropertyLoaded(:final items) when items.isEmpty => const _Notice(
          message: 'Aucun bien enregistré pour le moment.',
        ),
        PropertyLoaded(:final items) => _buildGrid(
          context,
          items.take(maxItems).toList(),
        ),
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<PropertyModel> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => PropertyCard(
        data: propertyCardData(items[i]),
        onTap: () =>
            context.router.push(PropertyDetailRoute(property: items[i])),
      ),
    );
  }
}

/// Message tenant la place de la grille, dans le cadre d'un état vide.
class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: EmptyState(message: message, icon: AppSectionIcons.properties),
    );
  }
}
