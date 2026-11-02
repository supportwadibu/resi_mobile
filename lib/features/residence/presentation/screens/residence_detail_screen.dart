import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/empty_state.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/router/app_router.gr.dart';
import '../../../../core/router/role_guard.dart';
import '../../../../core/session/session_role.dart';
import '../../../property/data/models/property_model.dart';
import '../../../property/data/repositories/property_repository.dart';
import '../../business_logic/residence_detail_cubit.dart';
import '../../business_logic/residence_detail_state.dart';
import '../../data/models/residence_model.dart';
import '../../data/repositories/residence_repository.dart';
import '../widgets/attach_unit_sheet.dart';
import '../widgets/residence_unit_tile.dart';
import 'package:resi_africa/shared/utils/ensure_online.dart';

/// Fiche d'une résidence : ses informations et les logements qu'elle regroupe.
@RoutePage()
class ResidenceDetailScreen extends StatelessWidget {
  const ResidenceDetailScreen({super.key, required this.residenceId});

  final String residenceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResidenceDetailCubit>()..load(residenceId),
      child: _ResidenceDetailView(residenceId: residenceId),
    );
  }
}

class _ResidenceDetailView extends StatelessWidget {
  const _ResidenceDetailView({required this.residenceId});

  final String residenceId;

  @override
  Widget build(BuildContext context) {
    // Le rôle se lit sur la session, comme partout ailleurs dans le projet.
    // La fiche reste ouverte au gérant : c'est son plan de travail. Seuls les
    // gestes qui la façonnent lui sont retirés — `/gerant/residences` est en
    // lecture seule.
    final role = sl<SessionRole>().value;
    final canEdit = isGestureAllowed(role, 'residence_edit');
    final canAttach = isGestureAllowed(role, 'residence_attach_unit');

    return Scaffold(
      appBar: AppTopBar(
        title: 'property_detail.residence'.tr(),
        actions: [
          BlocBuilder<ResidenceDetailCubit, ResidenceDetailState>(
            builder: (context, state) =>
                state is ResidenceDetailLoaded && canEdit
                ? AppButton(
                    label: 'common.edit'.tr(),
                    icon: LucideIcons.pencil,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.sm,
                    onPressed: () => _edit(context),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: BlocBuilder<ResidenceDetailCubit, ResidenceDetailState>(
        builder: (context, state) => switch (state) {
          ResidenceDetailInitial() ||
          ResidenceDetailLoading() => const Center(child: AppLoader()),
          ResidenceDetailError(:final message) => ErrorState(
            message: message,
            onRetry: () =>
                context.read<ResidenceDetailCubit>().load(residenceId),
          ),
          ResidenceDetailLoaded(
            :final residence,
            :final units,
            :final unitsFailed,
          ) =>
            RefreshIndicator(
              onRefresh: () =>
                  context.read<ResidenceDetailCubit>().load(residenceId),
              child: _Content(
                residence: residence,
                units: units,
                unitsFailed: unitsFailed,
                onAttach: canAttach
                    ? () => _attachUnit(context, residence)
                    : null,
              ),
            ),
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<ResidenceDetailCubit>();
    if (!await ensureOnline(context) || !context.mounted) return;
    await context.router.push(AddResidenceRoute(residenceId: residenceId));
    // Le formulaire a son propre cubit : ses écritures n'atteignent pas
    // celui-ci, qui doit donc relire la fiche au retour.
    await cubit.load(residenceId);
  }

  /// Rattache un logement encore libre à cette résidence.
  ///
  /// Les candidats sont les biens sans résidence : en proposer un déjà
  /// rattaché ailleurs le déplacerait sans que rien ne le dise.
  Future<void> _attachUnit(
    BuildContext context,
    ResidenceModel residence,
  ) async {
    final cubit = context.read<ResidenceDetailCubit>();
    final messenger = ScaffoldMessenger.of(context);

    List<PropertyModel> candidates;
    try {
      // Tout le parc, et non la première page : le filtre ci-dessous s'applique
      // à la liste reçue, et un logement isolé au-delà du 20e rang serait
      // invisible ici — donc impossible à rattacher, sans que rien ne le dise.
      final all = await sl<PropertyRepository>().getAllProperties();
      candidates = all.where((p) => !p.belongsToResidence).toList();
    } on AppFailure catch (f) {
      AppToast.error(f.userMessage);
      return;
    }

    if (!context.mounted) return;

    final picked = await AttachUnitSheet.show(
      context,
      residenceName: residence.name,
      candidates: candidates,
    );

    if (picked == null) return;

    try {
      await sl<ResidenceRepository>().attachToResidence(
        picked.id,
        residenceId: residence.id,
      );
    } on AppFailure catch (f) {
      AppToast.error(f.userMessage);
      return;
    }

    messenger.clearSnackBars();
    AppToast.success('residence.unit_attached'.tr());
    await cubit.load(residenceId);
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.residence,
    required this.units,
    required this.unitsFailed,
    required this.onAttach,
  });

  final ResidenceModel residence;
  final List<PropertyModel> units;
  final bool unitsFailed;

  /// Nul quand le rôle n'a pas le rattachement : l'en-tête de section se rend
  /// alors sans son bouton, plutôt qu'avec un bouton sans effet.
  final VoidCallback? onAttach;

  @override
  Widget build(BuildContext context) {
    final address = residence.address;
    final street = address.street.trim();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            const IconChip(icon: AppSectionIcons.residences, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(residence.name, style: context.text.headlineSmall),
                  const SizedBox(height: 2),
                  Text(
                    street.isEmpty ? address.city : '$street, ${address.city}',
                    maxLines: 2,
                    style: context.mutedText,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (residence.description.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Section(
            title: 'property_detail.description'.tr(),
            icon: LucideIcons.alignLeft,
            child: Text(
              residence.description,
              style: context.mutedText.copyWith(height: 1.55),
            ),
          ),
        ],
        if (residence.amenities.isNotEmpty) ...[
          const SizedBox(height: 12),
          Section(
            title: 'residence.common_areas'.tr(),
            icon: LucideIcons.listChecks,
            child: _AmenitiesList(amenities: residence.amenities),
          ),
        ],
        const SizedBox(height: 12),
        Section(
          title: units.isEmpty
              ? 'residence.units'.tr()
              : 'residence.units_count'.tr(args: ['${units.length}']),
          icon: AppSectionIcons.properties,
          padding: EdgeInsets.zero,
          actions: [
            if (onAttach != null)
              AppButton(
                label: 'property_detail.attach'.tr(),
                icon: LucideIcons.plus,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                onPressed: onAttach,
              ),
          ],
          child: unitsFailed
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: AppCallout(
                    icon: LucideIcons.circleAlert,
                    tone: AppAccent.red,
                    message: 'residence.units_load_failed'.tr(),
                  ),
                )
              : units.isEmpty
              ? EmptyState(
                  icon: AppSectionIcons.properties,
                  message: 'residence.no_units'.tr(),
                )
              : Column(
                  children: [
                    for (var i = 0; i < units.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ResidenceUnitTile(
                        unit: units[i],
                        onTap: () => context.router.push(
                          PropertyDetailRoute(property: units[i]),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _AmenitiesList extends StatelessWidget {
  const _AmenitiesList({required this.amenities});

  final Set<ResidenceAmenity> amenities;

  static const _icons = {
    ResidenceAmenity.pool: LucideIcons.waves,
    ResidenceAmenity.gym: LucideIcons.dumbbell,
    ResidenceAmenity.security: LucideIcons.shield,
    ResidenceAmenity.concierge: LucideIcons.headset,
    ResidenceAmenity.elevator: LucideIcons.arrowUpDown,
    ResidenceAmenity.parking: LucideIcons.squareParking,
    ResidenceAmenity.garden: LucideIcons.trees,
    ResidenceAmenity.wifi: LucideIcons.wifi,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final amenity in amenities)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: t.background,
              borderRadius: AppRadius.pill,
              border: Border.all(color: t.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _icons[amenity] ?? LucideIcons.check,
                  size: 14,
                  color: t.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  amenity.label,
                  style: context.text.bodySmall!.copyWith(color: t.foreground),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
