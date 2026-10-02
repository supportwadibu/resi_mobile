import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/confirm_dialog.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/skeletons/list_skeleton.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../business_logic/gerant_list_cubit.dart';
import '../../data/models/gerant_account_model.dart';
import '../widgets/gerant_card.dart';
import 'package:resi_africa/shared/utils/ensure_online.dart';

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
      appBar: AppTopBar(
        title: 'gerant.my_managers'.tr(),
        actions: [
          AppButton(
            label: 'common.add'.tr(),
            icon: LucideIcons.plus,
            size: AppButtonSize.sm,
            onPressed: () => _openForm(context),
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
            onRefresh: () => context.read<GerantListCubit>().load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
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
    if (!await ensureOnline(context) || !context.mounted) return;
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
    if (!await ensureOnline(context) || !context.mounted) return;
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

    final confirmed = await showConfirmDialog(
      context: context,
      title: suspendre
          ? 'gerant.suspend_title'.tr(args: [gerant.fullName])
          : 'gerant.reactivate_title'.tr(args: [gerant.fullName]),
      message: suspendre
          ? 'gerant.suspend_body'.tr()
          : 'gerant.reactivate_body'.tr(),
      confirmLabel: suspendre
          ? 'gerant.suspend'.tr()
          : 'gerant.reactivate'.tr(),
      danger: suspendre,
    );

    if (!confirmed) return;

    final error = await cubit.setStatus(gerant.id, isActive: !gerant.isActive);
    if (error != null) {
      AppToast.error(error);
      return;
    }

    AppToast.success(
      suspendre ? 'gerant.suspended'.tr() : 'gerant.reactivated'.tr(),
    );
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
    return EmptyState(
      icon: AppSectionIcons.managers,
      title: 'gerant.empty_title'.tr(),
      message: 'gerant.empty_body'.tr(),
      actionLabel: 'gerant.add'.tr(),
      actionIcon: LucideIcons.plus,
      onAction: onCreate,
    );
  }
}
