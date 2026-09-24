import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../../core/router/role_guard.dart';
import '../../../../core/session/session_role.dart';
import '../../business_logic/residence_cubit.dart';
import '../../business_logic/residence_state.dart';
import '../widgets/residence_card.dart';

/// Résidences du propriétaire — les lieux regroupant plusieurs logements.
@RoutePage()
class ResidenceScreen extends StatelessWidget {
  const ResidenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResidenceCubit>()..load(),
      child: const _ResidenceView(),
    );
  }
}

class _ResidenceView extends StatelessWidget {
  const _ResidenceView();

  @override
  Widget build(BuildContext context) {
    // Le rôle se lit sur la session, comme partout ailleurs dans le projet.
    // L'écran reste ouvert au gérant — les résidences situent ses logements —
    // mais `/gerant/residences` est en lecture seule : créer et supprimer lui
    // sont retirés ici plutôt que refusés à l'appui.
    final role = sl<SessionRole>().value;
    final canCreate = isGestureAllowed(role, 'residence_create');
    final canDelete = isGestureAllowed(role, 'residence_delete');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Mes résidences',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          if (canCreate)
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
      body: BlocBuilder<ResidenceCubit, ResidenceState>(
        builder: (context, state) => switch (state) {
          ResidenceInitial() || ResidenceLoading() => const SimpleListSkeleton(
            itemCount: 5,
            itemHeight: 108,
          ),
          ResidenceError(:final message) => _ErrorView(
            message: message,
            onRetry: () => context.read<ResidenceCubit>().load(),
          ),
          ResidenceLoaded(:final items) when items.isEmpty => _EmptyView(
            onCreate: canCreate ? () => _openForm(context) : null,
          ),
          ResidenceLoaded(:final items) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<ResidenceCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final residence = items[index];
                return ResidenceCard(
                  residence: residence,
                  onTap: () => _openDetail(context, residence.id),
                  onDelete: canDelete
                      ? () => _confirmDelete(context, residence.id)
                      : null,
                );
              },
            ),
          ),
        },
      ),
    );
  }

  /// Ouvre la fiche : détails du lieu et logements rattachés.
  ///
  /// L'édition s'y trouve derrière un bouton dédié — un clic sur la carte
  /// menait auparavant droit au formulaire, sans jamais montrer ce que la
  /// résidence contient.
  Future<void> _openDetail(BuildContext context, String id) async {
    final cubit = context.read<ResidenceCubit>();
    await context.router.push(ResidenceDetailRoute(residenceId: id));
    // Le compteur de logements et le nom peuvent avoir changé depuis la fiche.
    await cubit.load();
  }

  Future<void> _openForm(BuildContext context, {String? id}) async {
    final cubit = context.read<ResidenceCubit>();
    await context.router.push(AddResidenceRoute(residenceId: id));
    // La liste est rechargée au retour : le formulaire a son propre cubit, et
    // ses écritures n'atteignent donc pas celui de cette page.
    await cubit.load();
  }

  /// Demande confirmation, puis supprime.
  ///
  /// La suppression est refusée par le serveur tant que des logements sont
  /// rattachés : le message est affiché tel quel plutôt que traduit ici, lui
  /// seul sachant combien il en reste.
  Future<void> _confirmDelete(BuildContext context, String id) async {
    final cubit = context.read<ResidenceCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Supprimer cette résidence ?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Les logements qu’elle contient ne sont pas supprimés. '
          'Détachez-les d’abord si la suppression est refusée.',
          style: TextStyle(
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              'Supprimer',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final error = await cubit.delete(id);
    if (error != null) {
      AppToast.error(error);
      return;
    }

    AppToast.success('Résidence supprimée');
  }
}

/// Aucune résidence : l'écran explique la notion avant d'inviter à créer.
///
/// Une résidence se confond facilement avec un bien ; sans cette précision, le
/// propriétaire en crée une par logement.
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onCreate});

  /// Nul quand le rôle ne crée pas de résidence : l'explication reste, l'appel
  /// à créer disparaît. Inviter un gérant à un geste que le serveur lui refuse
  /// ne lui laisserait qu'une impasse.
  final VoidCallback? onCreate;

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
                Icons.apartment_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune résidence',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Une résidence regroupe plusieurs logements loués séparément — '
              'un studio, une chambre-salon — qui partagent une adresse et des '
              'charges communes.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (onCreate != null) ...[
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
                  'Créer une résidence',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Échec de chargement, avec de quoi réessayer.
///
/// Distinct de l'état vide : une liste sans résidence invite à en créer une,
/// une erreur réseau invite à relancer.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 34,
              color: AppColors.grey500,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Réessayer', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
