import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/features/property/business_logic/property_cubit.dart';
import 'package:resi_africa/features/property/business_logic/property_state.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';
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
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.78,
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

/// Message discret tenant la place de la grille.
class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.grey500),
        ),
      ),
    );
  }
}
