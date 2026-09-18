import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../business_logic/gerant_list_cubit.dart';
import '../../data/models/gerant_account_model.dart';
import '../widgets/gerant_card.dart';

/// Gérants du propriétaire — les comptes à qui il confie une partie du parc.
@RoutePage()
class GerantListScreen extends StatelessWidget {
  const GerantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GerantListCubit>()..load(),
      child: const _GerantListView(),
    );
  }
}

class _GerantListView extends StatelessWidget {
  const _GerantListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Mes gérants',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _openForm(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<GerantListCubit, GerantListState>(
        builder: (context, state) => switch (state) {
          GerantListInitial() ||
          GerantListLoading() => const SimpleListSkeleton(
            itemCount: 5,
            itemHeight: 96,
          ),
          GerantListError(:final message) => ErrorState(
            message: message,
            onRetry: () => context.read<GerantListCubit>().load(),
          ),
          GerantListLoaded(:final items) when items.isEmpty => _EmptyView(
            onCreate: () => _openForm(context),
          ),
          GerantListLoaded(:final items) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<GerantListCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final gerant = items[index];
                return GerantCard(
                  gerant: gerant,
                  onTap: () => _openScope(context, gerant),
                  onToggleStatus: () => _confirmStatus(context, gerant),
                );
              },
            ),
          ),
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context) async {
    final cubit = context.read<GerantListCubit>();
    await context.router.push(const AddGerantRoute());
    // La liste est relue au retour : le formulaire a son propre cubit, et ses
    // écritures n'atteignent donc pas celui de cette page.
    await cubit.load();
  }

  /// Ouvre le périmètre du gérant.
  ///
  /// C'est l'action principale de la carte : le compte une fois ouvert, c'est
  /// la liste des logements confiés que le propriétaire revient modifier.
  Future<void> _openScope(BuildContext context, GerantAccountModel g) async {
    final cubit = context.read<GerantListCubit>();
    await context.router.push(
      GerantScopeRoute(gerantId: g.id, gerantName: g.fullName),
    );
    // Le nombre de logements affiché sur la carte a pu changer.
    await cubit.load();
  }

  /// Demande confirmation avant de suspendre ou de réactiver.
  ///
  /// La suspension ne supprime rien : le dialogue le dit, sans quoi le
  /// propriétaire hésite à s'en servir de peur de perdre l'historique.
  Future<void> _confirmStatus(
    BuildContext context,
    GerantAccountModel gerant,
  ) async {
    final cubit = context.read<GerantListCubit>();
    final suspendre = gerant.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          suspendre
              ? 'Suspendre ${gerant.fullName} ?'
              : 'Réactiver ${gerant.fullName} ?',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          suspendre
              ? 'Il ne pourra plus se connecter. Son périmètre et les '
                    'réservations qu’il a saisies sont conservés.'
              : 'Il retrouvera l’accès aux logements qui lui sont confiés.',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text('Annuler', style: TextStyle(fontSize: 13)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: suspendre ? AppColors.error : AppColors.success,
            ),
            child: Text(
              suspendre ? 'Suspendre' : 'Réactiver',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final error = await cubit.setStatus(gerant.id, isActive: !gerant.isActive);
    if (error != null) {
      AppToast.error(error);
      return;
    }

    AppToast.success(suspendre ? 'Gérant suspendu' : 'Gérant réactivé');
  }
}

/// Aucun gérant : l'écran explique la notion avant d'inviter à en créer un.
///
/// Un gérant se confond avec un client ou un propriétaire second ; sans cette
/// précision, le propriétaire ne voit pas ce que le compte lui apporte.
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.infoBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.badge_outlined,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun gérant',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Un gérant encaisse les réservations et suit les dépenses des '
              'seuls logements que vous lui confiez. Il ne voit ni vos '
              'revenus, ni vos autres biens.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Ajouter un gérant',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
