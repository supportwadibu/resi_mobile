import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Résidence',
          style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<ResidenceDetailCubit, ResidenceDetailState>(
            builder: (context, state) =>
                state is ResidenceDetailLoaded && canEdit
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => _edit(context),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Modifier',
                          style: AppTextStyles.valueSmall.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: BlocBuilder<ResidenceDetailCubit, ResidenceDetailState>(
        builder: (context, state) => switch (state) {
          ResidenceDetailInitial() || ResidenceDetailLoading() => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          ResidenceDetailError(:final message) => _ErrorView(
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
              color: AppColors.primary,
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
    AppToast.success('Logement rattaché');
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _HeaderCard(residence: residence),

        if (residence.description.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle('Description'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              residence.description,
              style: AppTextStyles.labelMedium.copyWith(height: 1.6),
            ),
          ),
        ],

        if (residence.amenities.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionTitle('Parties communes'),
          const SizedBox(height: 10),
          _AmenitiesCard(amenities: residence.amenities),
        ],

        const SizedBox(height: 20),
        Row(
          children: [
            _SectionTitle(
              units.isEmpty ? 'Logements' : 'Logements · ${units.length}',
            ),
            const Spacer(),
            if (onAttach != null)
              GestureDetector(
                onTap: onAttach,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Rattacher',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (unitsFailed)
          const _UnitsNotice(
            'Les logements n’ont pas pu être chargés. Tirez pour réessayer.',
            isError: true,
          )
        else if (units.isEmpty)
          const _UnitsNotice(
            'Aucun logement rattaché. Une résidence sans logement n’est pas '
            'encore louable.',
          )
        else
          for (final unit in units)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ResidenceUnitTile(
                unit: unit,
                onTap: () =>
                    context.router.push(PropertyDetailRoute(property: unit)),
              ),
            ),
      ],
    );
  }
}

/// Nom, adresse et nombre de logements.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.residence});

  final ResidenceModel residence;

  @override
  Widget build(BuildContext context) {
    final address = residence.address;
    final street = address.street.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      residence.name,
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            street.isEmpty
                                ? address.city
                                : '$street, ${address.city}',
                            maxLines: 2,
                            style: AppTextStyles.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmenitiesCard extends StatelessWidget {
  const _AmenitiesCard({required this.amenities});

  final Set<ResidenceAmenity> amenities;

  static const _icons = {
    ResidenceAmenity.pool: Icons.pool_outlined,
    ResidenceAmenity.gym: Icons.fitness_center_outlined,
    ResidenceAmenity.security: Icons.shield_outlined,
    ResidenceAmenity.concierge: Icons.support_agent_outlined,
    ResidenceAmenity.elevator: Icons.elevator_outlined,
    ResidenceAmenity.parking: Icons.local_parking_outlined,
    ResidenceAmenity.garden: Icons.park_outlined,
    ResidenceAmenity.wifi: Icons.wifi_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final amenity in amenities)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _icons[amenity] ?? Icons.check_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(amenity.label, style: AppTextStyles.labelSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.sectionTitle.copyWith(fontSize: 13));
  }
}

/// Message tenant la place de la liste des logements.
class _UnitsNotice extends StatelessWidget {
  const _UnitsNotice(this.message, {this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorBg : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: AppTextStyles.labelMedium.copyWith(
          height: 1.5,
          color: isError ? AppColors.error : AppColors.textSecondary,
        ),
      ),
    );
  }
}

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
              style: AppTextStyles.labelMedium.copyWith(height: 1.5),
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
