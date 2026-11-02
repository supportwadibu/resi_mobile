import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';
import 'package:resi_africa/shared/widgets/app_city_field.dart';
import 'package:resi_africa/shared/widgets/app_step_header.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:resi_africa/shared/widgets/loading_shimmer.dart';
import 'package:resi_africa/shared/widgets/skeletons/form_skeleton.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/residence_cubit.dart';
import '../../business_logic/residence_state.dart';
import '../../data/models/residence_model.dart';
import '../../data/repositories/residence_repository.dart';

/// Saisie d'une résidence — création, ou modification si [residenceId] est
/// fourni.
///
/// La fiche est relue au serveur plutôt que passée en argument : l'écran est
/// atteignable depuis plusieurs endroits, et transporter le modèle obligerait
/// chaque appelant à le détenir déjà.
///
/// Contrairement au dépôt d'un bien, la saisie tient sur une seule page : trois
/// champs et une liste de cases à cocher ne justifient pas un assistant.
@RoutePage()
class AddResidenceScreen extends StatelessWidget {
  const AddResidenceScreen({super.key, @QueryParam('id') this.residenceId});

  final String? residenceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResidenceCubit>(),
      child: _AddResidenceView(residenceId: residenceId),
    );
  }
}

class _AddResidenceView extends StatefulWidget {
  const _AddResidenceView({this.residenceId});

  final String? residenceId;

  @override
  State<_AddResidenceView> createState() => _AddResidenceViewState();
}

class _AddResidenceViewState extends State<_AddResidenceView> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();

  final _amenities = <ResidenceAmenity>{};

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _loadError;

  ResidenceModel? _original;

  bool get _isEditing => widget.residenceId != null;

  /// Pays dont la liste de villes est proposée.
  ///
  /// Le formulaire ne présente pas de champ pays — la plateforme n'opère qu'en
  /// Côte d'Ivoire. En modification, le pays de la fiche enregistrée prime
  /// néanmoins : une résidence saisie ailleurs verrait sinon sa ville proposée
  /// depuis la mauvaise liste.
  String get _countryIso2 => _original?.address.country ?? 'CI';

  /// Une icône par équipement de partie commune.
  ///
  /// Même registre que les commodités d'un bien, pour que les deux écrans se
  /// lisent de la même façon.
  static const _amenityIcons = <ResidenceAmenity, IconData>{
    ResidenceAmenity.pool: LucideIcons.waves,
    ResidenceAmenity.gym: LucideIcons.dumbbell,
    ResidenceAmenity.security: LucideIcons.shieldHalf,
    ResidenceAmenity.concierge: LucideIcons.conciergeBell,
    ResidenceAmenity.elevator: LucideIcons.arrowUpDown,
    ResidenceAmenity.parking: LucideIcons.car,
    ResidenceAmenity.garden: LucideIcons.treePine,
    ResidenceAmenity.wifi: LucideIcons.wifi,
  };

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadExisting();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);

    try {
      final residence = await sl<ResidenceRepository>().getResidence(
        widget.residenceId!,
      );
      if (!mounted) return;

      setState(() {
        _original = residence;
        _nameController.text = residence.name;
        _descriptionController.text = residence.description;
        _streetController.text = residence.address.street;
        _cityController.text = residence.address.city;
        _amenities
          ..clear()
          ..addAll(residence.amenities);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Message bloquant, ou `null` si la saisie est complète.
  ///
  /// Les règles reprennent celles du validateur serveur : mieux vaut un refus
  /// immédiat et situé qu'une erreur 422 après coup.
  String? _validate() {
    if (_nameController.text.trim().length < 2) {
      return 'residence.name_required'.tr();
    }
    if (_streetController.text.trim().length < 2) {
      return 'residence.street_required'.tr();
    }
    if (_cityController.text.trim().length < 2) {
      return 'residence.city_required'.tr();
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      _showMessage(error);
      return;
    }

    setState(() => _isSubmitting = true);

    final cubit = context.read<ResidenceCubit>();
    final address = ResidenceAddress(
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      // L'adresse enregistrée porte un pays et un code postal que le formulaire
      // ne présente pas : les reprendre évite qu'un enregistrement les efface.
      country: _countryIso2,
      postalCode: _original?.address.postalCode,
    );

    final result = _isEditing
        ? await cubit.update(
            widget.residenceId!,
            UpdateResidencePayload(
              name: _nameController.text,
              description: _descriptionController.text,
              address: address,
              amenities: _amenities,
            ),
          )
        : await cubit.create(
            CreateResidencePayload(
              name: _nameController.text,
              address: address,
              description: _descriptionController.text,
              amenities: _amenities,
            ),
          );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      AppToast.success(
        _isEditing ? 'residence.updated'.tr() : 'residence.created'.tr(),
        context: context,
      );
      context.router.maybePop();
      return;
    }

    // `null` sans changement à envoyer n'est pas un échec : le patch était vide.
    if (_isEditing && _hasNoChange()) {
      context.router.maybePop();
      return;
    }

    final state = cubit.state;
    _showMessage(
      state is ResidenceError
          ? state.message
          : 'residence.save_impossible'.tr(),
    );
  }

  /// Rien n'a bougé : inutile d'appeler l'API, mais l'écran doit se fermer
  /// comme après un enregistrement réussi.
  bool _hasNoChange() {
    final original = _original;
    if (original == null) return false;

    return _nameController.text.trim() == original.name &&
        _descriptionController.text.trim() == original.description &&
        _streetController.text.trim() == original.address.street &&
        _cityController.text.trim() == original.address.city &&
        _amenities.length == original.amenities.length &&
        _amenities.containsAll(original.amenities);
  }

  void _showMessage(String message) {
    AppToast.error(message, context: context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isSubmitting,
          child: Column(
            children: [
              AppStepHeader(
                title: _isEditing
                    ? 'residence.edit_title'.tr()
                    : 'residence.new_title'.tr(),
                onBack: () => context.router.maybePop(),
              ),

              Expanded(
                child: switch ((_isLoading, _loadError)) {
                  (true, _) => const _FormSkeleton(),
                  (_, final String error) => _LoadErrorView(
                    message: error,
                    onRetry: _loadExisting,
                  ),
                  _ => SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _form(),
                  ),
                },
              ),

              // La barre reste en place pendant le chargement de la fiche, mais
              // sans action : elle ancre l'écran, et un bouton actif enverrait
              // un formulaire encore vide.
              if (_loadError == null)
                AppBottomActionBar(
                  primaryLabel: _isSubmitting
                      ? 'property_form.saving'.tr()
                      : (_isEditing
                            ? 'common.save'.tr()
                            : 'residence.create'.tr()),
                  onPrimary: _isLoading ? null : _submit,
                  primaryIcon: LucideIcons.check,
                  isLoading: _isSubmitting,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: 'residence.name_question'.tr(),
          subtitle: 'residence.name_question_hint'.tr(),
        ),
        const SizedBox(height: 20),

        AppTextField(
          label: 'residence.name'.tr(),
          hint: 'residence.name_hint'.tr(),
          controller: _nameController,
          prefixIcon: const Icon(LucideIcons.building2, size: 18),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'residence.description_optional'.tr(),
          hint: 'residence.description_hint'.tr(),
          controller: _descriptionController,
          maxLines: 4,
        ),

        const SizedBox(height: 32),
        _SectionTitle(
          title: 'residence.where'.tr(),
          subtitle: 'residence.where_hint'.tr(),
        ),
        const SizedBox(height: 20),

        // Le pays n'est pas saisi ici : une résidence est en Côte d'Ivoire,
        // comme le suppose déjà `ResidenceAddress.country`. Le champ ouvre donc
        // directement la liste des villes ivoiriennes.
        AppCityField(countryIso2: _countryIso2, controller: _cityController),
        const SizedBox(height: 16),
        AppTextField(
          label: 'property_form.full_address'.tr(),
          hint: 'property_form.full_address_hint'.tr(),
          controller: _streetController,
          prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
        ),

        const SizedBox(height: 32),
        _SectionTitle(
          title: 'residence.common_areas'.tr(),
          subtitle: 'residence.common_areas_hint'.tr(),
          trailing: 'property_form.selected_count'.tr(
            args: ['${_amenities.length}'],
          ),
        ),
        const SizedBox(height: 16),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.8,
          ),
          itemCount: ResidenceAmenity.values.length,
          itemBuilder: (_, i) {
            final amenity = ResidenceAmenity.values[i];
            return _AmenityTile(
              icon: _amenityIcons[amenity] ?? LucideIcons.check,
              label: amenity.label,
              isSelected: _amenities.contains(amenity),
              onTap: () => setState(() {
                if (!_amenities.remove(amenity)) _amenities.add(amenity);
              }),
            );
          },
        ),
      ],
    );
  }
}

/// Squelette du formulaire, le temps de relire la fiche à modifier.
///
/// Reproduit l'enchaînement réel — deux titres de section, les quatre champs,
/// puis la grille des parties communes — pour que rien ne se décale à l'arrivée
/// du contenu.
class _FormSkeleton extends StatelessWidget {
  const _FormSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: SingleChildScrollView(
        // Le formulaire réel défile : sans cela le squelette déborde sur les
        // écrans courts, là où le contenu qu'il annonce tient sans peine.
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre « Comment s'appelle cette résidence ? » et son explication.
            const LoadingShimmer(height: 15, width: 230),
            const SizedBox(height: 8),
            const LoadingShimmer(height: 12, width: 280),
            const SizedBox(height: 20),
            const FieldSkeleton(labelWidth: 130),
            const SizedBox(height: 16),
            // Description : quatre lignes de saisie.
            const LoadingShimmer(height: 13, width: 150),
            const SizedBox(height: 8),
            const LoadingShimmer(height: 110),

            const SizedBox(height: 32),
            const LoadingShimmer(height: 15, width: 200),
            const SizedBox(height: 8),
            const LoadingShimmer(height: 12, width: 260),
            const SizedBox(height: 20),
            const FieldSkeleton(labelWidth: 45),
            const SizedBox(height: 16),
            const FieldSkeleton(labelWidth: 120),

            const SizedBox(height: 32),
            const LoadingShimmer(height: 15, width: 150),
            const SizedBox(height: 8),
            const LoadingShimmer(height: 12, width: 290),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.8,
              ),
              itemCount: ResidenceAmenity.values.length,
              itemBuilder: (_, _) => const LoadingShimmer(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Titre de section du formulaire, avec son explication.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;

  /// Compteur aligné à droite du titre, quand la section en a un.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: context.text.titleMedium)),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Text(trailing!, style: context.text.bodySmall),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: context.text.bodySmall),
      ],
    );
  }
}

/// Équipement de partie commune, coché ou non.
class _AmenityTile extends StatelessWidget {
  const _AmenityTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Même allure qu'`AppChoiceChip` — choix multiple, noir une fois coché —
    // étirée à la case de la grille.
    final t = context.tokens;
    final fg = isSelected ? t.primaryForeground : t.foreground;
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? t.primary : t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: BorderSide(color: isSelected ? t.primary : t.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, size: 14, color: isSelected ? fg : t.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium!.copyWith(color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La fiche à modifier n'a pas pu être relue.
///
/// Distinct d'un échec d'enregistrement : sans la fiche d'origine, le
/// formulaire ne peut pas s'ouvrir du tout.
class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorState(message: message, onRetry: onRetry);
  }
}
