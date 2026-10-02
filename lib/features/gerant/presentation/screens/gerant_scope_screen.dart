import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      appBar: AppTopBar(title: 'gerant.assigned_units'.tr()),
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
            EmptyState(
              icon: LucideIcons.doorOpen,
              message: 'gerant.no_unit_owned'.tr(),
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
          primaryLabel: 'common.save'.tr(),
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

    AppToast.success('gerant.scope_saved'.tr());
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

    // Périmètre vide : ambre, comme tout ce qui attend une action.
    return AppCallout(
      icon: isEmpty ? LucideIcons.info : LucideIcons.doorOpen,
      tone: isEmpty ? AppAccent.amber : AppAccent.blue,
      title: gerantName == null
          ? 'gerant.scope_count'.plural(
              selectedCount,
              namedArgs: {
                'selected': '$selectedCount',
                'total': '$totalCount',
              },
            )
          : 'gerant.scope_count_named'.plural(
              selectedCount,
              namedArgs: {
                'selected': '$selectedCount',
                'total': '$totalCount',
                'name': gerantName!,
              },
            ),
      message: isEmpty
          ? 'gerant.scope_empty'.tr()
          : 'gerant.scope_body'.tr(),
    );
  }
}
