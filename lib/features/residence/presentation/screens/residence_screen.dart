import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/confirm_dialog.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
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
      appBar: AppTopBar(
        title: 'Mes résidences',
        actions: [
          if (canCreate)
            AppButton(
              label: 'Nouvelle',
              icon: LucideIcons.plus,
              size: AppButtonSize.sm,
              onPressed: () => _openForm(context),
            ),
        ],
      ),
      body: BlocBuilder<ResidenceCubit, ResidenceState>(
        builder: (context, state) => switch (state) {
          ResidenceInitial() || ResidenceLoading() => const SimpleListSkeleton(
            itemCount: 5,
            itemHeight: 108,
          ),
          ResidenceError(:final message) => ErrorState(
            message: message,
            onRetry: () => context.read<ResidenceCubit>().load(),
          ),
          ResidenceLoaded(:final items) when items.isEmpty => _EmptyView(
            onCreate: canCreate ? () => _openForm(context) : null,
          ),
          ResidenceLoaded(:final items) => RefreshIndicator(
            onRefresh: () => context.read<ResidenceCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
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

    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Supprimer cette résidence ?',
      message:
          'Les logements qu’elle contient ne sont pas supprimés. '
          'Détachez-les d’abord si la suppression est refusée.',
      confirmLabel: 'Supprimer',
      danger: true,
    );

    if (!confirmed) return;

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
    return EmptyState(
      icon: AppSectionIcons.residences,
      title: 'Aucune résidence',
      message:
          'Une résidence regroupe plusieurs logements loués séparément — '
          'un studio, une chambre-salon — qui partagent une adresse et des '
          'charges communes.',
      actionLabel: onCreate == null ? null : 'Créer une résidence',
      actionIcon: LucideIcons.plus,
      onAction: onCreate,
    );
  }
}
