import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/features/property/business_logic/property_cubit.dart';
import 'package:resi_africa/features/property/business_logic/property_state.dart';
import 'package:resi_africa/features/property/data/models/property_model.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/filter_bottom_sheet.dart';
import 'package:resi_africa/shared/widgets/property_card.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';
import '../../../../../core/error/failures.dart';
import '../../../../residence/data/models/residence_model.dart';
import '../../../../residence/data/repositories/residence_repository.dart';
import '../../../../residence/presentation/widgets/attach_residence_sheet.dart';

/// Onglet « Mes biens » : les annonces du propriétaire connecté.
class PropertyTab extends StatelessWidget {
  const PropertyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PropertyCubit>()..load(),
      child: const _PropertyTabView(),
    );
  }
}

class _PropertyTabView extends StatefulWidget {
  const _PropertyTabView();

  @override
  State<_PropertyTabView> createState() => _PropertyTabViewState();
}

class _PropertyTabViewState extends State<_PropertyTabView> {
  bool _isGrid = true;

  /// Relance la liste au retour de l'écran de dépôt, pour que l'annonce
  /// tout juste créée y figure sans que l'utilisateur ait à rafraîchir.
  Future<void> _openAddProperty() async {
    await context.router.push(const AddPropertyRoute());
    if (mounted) context.read<PropertyCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    // Un `Scaffold` comme les autres onglets : le `Column` nu que rendait
    // cette vue n'avait pas de hauteur bornée dans l'`IndexedStack` de
    // l'écran d'accueil, d'où l'échec de mise en page (`hasSize`).
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            // L'encoche est déjà traitée par le `SafeArea` de l'écran hôte.
            child: Row(
              children: [
                const Text(
                  'Mes biens',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const Spacer(),
                AppButton(
                  onPressed: _openAddProperty,
                  label: 'Ajouter un bien',
                  backgroundColor: AppColors.black,
                  leadingIcon: AppButtonIcon.material(Icons.add, size: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: BlocBuilder<PropertyCubit, PropertyState>(
              builder: (context, state) => switch (state) {
                PropertyInitial() ||
                PropertyLoading() => const PropertyListSkeleton(),
                PropertyError(:final message) => _ErrorView(
                  message: message,
                  onRetry: () => context.read<PropertyCubit>().load(),
                ),
                PropertyLoaded(:final items) when items.isEmpty => _EmptyView(
                  onAdd: _openAddProperty,
                ),
                PropertyLoaded(:final items) => _buildContent(items),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<PropertyModel> items) {
    return RefreshIndicator(
      onRefresh: () => context.read<PropertyCubit>().load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppColors.grey400, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Rechercher un bien...',
                          style: TextStyle(
                            color: AppColors.grey400,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    await FilterBottomSheet.show(context);
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.black,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Text(
                  items.length > 1
                      ? '${items.length} propriétés trouvées'
                      : '${items.length} propriété trouvée',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const Spacer(),
                _ToggleButton(
                  icon: Icons.grid_view_rounded,
                  isActive: _isGrid,
                  onTap: () => setState(() => _isGrid = true),
                ),
                const SizedBox(width: 8),
                _ToggleButton(
                  icon: Icons.view_list_rounded,
                  isActive: !_isGrid,
                  onTap: () => setState(() => _isGrid = false),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _isGrid ? _buildGrid(items) : _buildList(items),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<PropertyModel> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => PropertyCard(
        data: propertyCardData(items[i]),
        isListMode: false,
        onTap: () => _openDetail(items[i]),
        onLongPress: () => _attachResidence(items[i]),
        onDelete: () => _confirmDelete(items[i]),
        onShare: () {},
      ),
    );
  }

  Widget _buildList(List<PropertyModel> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => PropertyCard(
        data: propertyCardData(items[i]),
        isListMode: true,
        onTap: () => _openDetail(items[i]),
        onLongPress: () => _attachResidence(items[i]),
        onDelete: () => _confirmDelete(items[i]),
        onShare: () {},
      ),
    );
  }

  /// Ouvre la fiche, puis recharge : le bien a pu y être modifié.
  Future<void> _openDetail(PropertyModel property) async {
    await context.router.push(PropertyDetailRoute(property: property));
    if (mounted) context.read<PropertyCubit>().load();
  }

  /// Rattache le bien à une résidence, ou l’en détache.
  ///
  /// Appui long plutôt qu’un bouton : l’action est occasionnelle, et la carte
  /// est déjà dense. Les résidences sont lues à l’ouverture, la feuille devant
  /// proposer la liste à jour.
  Future<void> _attachResidence(PropertyModel property) async {
    final messenger = ScaffoldMessenger.of(context);
    final repository = sl<ResidenceRepository>();

    List<ResidenceModel> residences;
    try {
      residences = await repository.getAllResidences();
    } on AppFailure catch (f) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(f.userMessage)));
      return;
    }

    if (!mounted) return;

    final result = await showModalBottomSheet<AttachResidenceResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AttachResidenceSheet(
        residences: residences,
        propertyTitle: property.title,
        currentResidenceId: property.residenceId,
        currentUnitLabel: property.unitLabel,
      ),
    );

    if (result == null || !mounted) return;

    try {
      await repository.attachToResidence(
        property.id,
        residenceId: result.residenceId,
        unitLabel: result.unitLabel,
        copyAddress: result.copyAddress,
      );
      if (mounted) context.read<PropertyCubit>().load();
    } on AppFailure catch (f) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(f.userMessage)));
    }
  }

  void _confirmDelete(PropertyModel property) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce bien ?'),
        content: Text('Voulez-vous supprimer "${property.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aucune annonce déposée : l'action utile est mise en avant.
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 56, color: AppColors.grey400),
            const SizedBox(height: 16),
            const Text(
              'Aucun bien enregistré',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Déposez votre première annonce pour la voir apparaître ici.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.grey500),
            ),
            const SizedBox(height: 20),
            AppButton(
              onPressed: onAdd,
              label: 'Ajouter un bien',
              backgroundColor: AppColors.black,
              leadingIcon: AppButtonIcon.material(Icons.add, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Échec de chargement : le message du serveur, et une seconde tentative.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.black),
            ),
            const SizedBox(height: 20),
            AppButton(
              onPressed: onRetry,
              label: 'Réessayer',
              backgroundColor: AppColors.black,
              leadingIcon: AppButtonIcon.material(Icons.refresh, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? AppColors.black : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? AppColors.white : AppColors.grey400,
        ),
      ),
    );
  }
}
