import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/gerant_scope_cubit.dart';
import '../widgets/scope_selector.dart';

/// Logements confiés à un gérant.
///
/// L'enregistrement est un `PUT` du périmètre complet : un ajout et un retrait
/// faits ensemble deviennent une seule écriture, et l'état obtenu ne dépend pas
/// de l'ordre des requêtes.
@RoutePage()
class GerantScopeScreen extends StatelessWidget {
  const GerantScopeScreen({
    super.key,
    required this.gerantId,
    this.gerantName,
  });

  final String gerantId;

  /// Nom affiché en sous-titre. Optionnel : la route est atteignable sans que
  /// l'appelant détienne la fiche, et le périmètre reste modifiable sans lui.
  final String? gerantName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GerantScopeCubit>()..load(gerantId: gerantId),
      child: _GerantScopeView(gerantId: gerantId, gerantName: gerantName),
    );
  }
}

class _GerantScopeView extends StatelessWidget {
  const _GerantScopeView({required this.gerantId, this.gerantName});

  final String gerantId;
  final String? gerantName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Logements confiés',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<GerantScopeCubit, GerantScopeState>(
        builder: (context, state) => switch (state) {
          GerantScopeInitial() ||
          GerantScopeLoading() => const SimpleListSkeleton(
            itemCount: 6,
            itemHeight: 64,
          ),
          GerantScopeError(:final message) => ErrorState(
            message: message,
            onRetry: () =>
                context.read<GerantScopeCubit>().load(gerantId: gerantId),
          ),
          GerantScopeLoaded(:final totalCount) when totalCount == 0 =>
            const EmptyState(
              icon: Icons.meeting_room_outlined,
              message:
                  'Vous n’avez aucun logement à confier. Ajoutez un bien '
                  'avant de composer un périmètre.',
            ),
          GerantScopeLoaded() => _ScopeBody(
            state: state,
            gerantId: gerantId,
            gerantName: gerantName,
          ),
        },
      ),
    );
  }
}

class _ScopeBody extends StatelessWidget {
  const _ScopeBody({
    required this.state,
    required this.gerantId,
    this.gerantName,
  });

  final GerantScopeLoaded state;
  final String gerantId;
  final String? gerantName;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GerantScopeCubit>();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScopeSummary(
                  selectedCount: state.selection.length,
                  totalCount: state.totalCount,
                  gerantName: gerantName,
                ),
                const SizedBox(height: 16),
                ScopeSelector(
                  groups: state.groups,
                  standalone: state.standalone,
                  selection: state.selection,
                  onToggleResidence: cubit.toggleResidenceSelection,
                  onToggleProperty: cubit.togglePropertySelection,
                ),
              ],
            ),
          ),
        ),
        AppBottomActionBar(
          primaryLabel: 'Enregistrer',
          isLoading: state.isSaving,
          onPrimary: state.isSaving ? null : () => _save(context),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final cubit = context.read<GerantScopeCubit>();
    final router = context.router;

    final error = await cubit.save(gerantId);
    if (error != null) {
      AppToast.error(error);
      return;
    }

    AppToast.success('Périmètre enregistré');
    router.maybePop();
  }
}

/// Rappelle ce qui est confié, et à qui.
///
/// Un périmètre vide est signalé comme tel plutôt que laissé à deviner : le
/// gérant ne verra alors strictement rien, ce qui ressemble à une panne sans
/// cet avertissement.
class ScopeSummary extends StatelessWidget {
  const ScopeSummary({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    this.gerantName,
  });

  final int selectedCount;
  final int totalCount;
  final String? gerantName;

  @override
  Widget build(BuildContext context) {
    final isEmpty = selectedCount == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEmpty ? AppColors.warningBg : AppColors.infoBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gerantName == null
                ? '$selectedCount logement${selectedCount > 1 ? 's' : ''} '
                      'sur $totalCount'
                : '$selectedCount logement${selectedCount > 1 ? 's' : ''} '
                      'sur $totalCount confié${selectedCount > 1 ? 's' : ''} '
                      'à $gerantName',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isEmpty
                ? 'Sans logement, le gérant se connecte mais ne voit rien.'
                : 'Il encaisse les réservations et suit les dépenses de ces '
                      'logements seulement.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
