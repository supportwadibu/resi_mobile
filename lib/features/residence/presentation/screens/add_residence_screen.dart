import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/app_bottom_action_bar.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
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
  static const _amenityIcons = <ResidenceAmenity, FaIconData>{
    ResidenceAmenity.pool: FontAwesomeIcons.personSwimming,
    ResidenceAmenity.gym: FontAwesomeIcons.dumbbell,
    ResidenceAmenity.security: FontAwesomeIcons.shieldHalved,
    ResidenceAmenity.concierge: FontAwesomeIcons.bellConcierge,
    ResidenceAmenity.elevator: FontAwesomeIcons.elevator,
    ResidenceAmenity.parking: FontAwesomeIcons.car,
    ResidenceAmenity.garden: FontAwesomeIcons.tree,
    ResidenceAmenity.wifi: FontAwesomeIcons.wifi,
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
      return 'Donnez un nom à la résidence.';
    }
    if (_streetController.text.trim().length < 2) {
      return 'Indiquez la rue.';
    }
    if (_cityController.text.trim().length < 2) {
      return 'Indiquez la ville.';
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
        _isEditing ? 'Résidence modifiée' : 'Résidence créée',
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
      state is ResidenceError ? state.message : 'Enregistrement impossible.',
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
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isSubmitting,
          child: Column(
            children: [
              AppStepHeader(
                title: _isEditing
                    ? 'Modifier la résidence'
                    : 'Nouvelle résidence',
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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
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
                      ? 'Enregistrement...'
                      : (_isEditing ? 'Enregistrer' : 'Créer la résidence'),
                  onPrimary: _isLoading ? null : _submit,
                  primaryIcon: AppButtonIcon.material(Icons.check_rounded),
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
        const _SectionTitle(
          title: 'Comment s’appelle cette résidence ?',
          subtitle: 'Le nom du lieu, celui que vous employez pour en parler.',
        ),
        const SizedBox(height: 20),

        AppTextField(
          label: 'Nom de la résidence',
          hint: 'Ex: Resi Adja, Résidence les Palmiers...',
          controller: _nameController,
          prefixIcon: const Icon(Icons.apartment_outlined, size: 18),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Description (facultatif)',
          hint: 'Ex: Trois logements à Cocody, cour commune...',
          controller: _descriptionController,
          maxLines: 4,
        ),

        const SizedBox(height: 32),
        const _SectionTitle(
          title: 'Où se trouve la résidence ?',
          subtitle: 'Cette adresse est celle de tous les logements du lieu.',
        ),
        const SizedBox(height: 20),

        // Le pays n'est pas saisi ici : une résidence est en Côte d'Ivoire,
        // comme le suppose déjà `ResidenceAddress.country`. Le champ ouvre donc
        // directement la liste des villes ivoiriennes.
        AppCityField(countryIso2: _countryIso2, controller: _cityController),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Adresse complète',
          hint: 'Ex: Rue des Jardins, Cocody...',
          controller: _streetController,
          prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
        ),

        const SizedBox(height: 32),
        _SectionTitle(
          title: 'Parties communes',
          subtitle:
              'Ce qui appartient au lieu, et non à un logement en particulier.',
          trailing: '${_amenities.length} sélectionnée(s)',
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
              icon: _amenityIcons[amenity] ?? FontAwesomeIcons.check,
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
            const LoadingShimmer(height: 15, width: 230, radius: 4),
            const SizedBox(height: 8),
            const LoadingShimmer(height: 12, width: 280, radius: 4),
            const SizedBox(height: 20),
            const FieldSkeleton(labelWidth: 130),
            const SizedBox(height: 16),
            // Description : quatre lignes de saisie.
            const LoadingShimmer(height: 13, width: 150, radius: 4),
            const SizedBox(height: 8),
            const LoadingShimmer(height: 110, radius: 12),

            const SizedBox(height: 32),
            const LoadingShimmer(height: 15, width: 200, radius: 4),
            const SizedBox(height: 8),
            const LoadingShimmer(height: 12, width: 260, radius: 4),
            const SizedBox(height: 20),
            const FieldSkeleton(labelWidth: 45),
            const SizedBox(height: 16),
            const FieldSkeleton(labelWidth: 120),

            const SizedBox(height: 32),
            const LoadingShimmer(height: 15, width: 150, radius: 4),
            const SizedBox(height: 8),
            const LoadingShimmer(height: 12, width: 290, radius: 4),
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
              itemBuilder: (_, _) => const LoadingShimmer(radius: 12),
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
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Text(
                trailing!,
                style: const TextStyle(fontSize: 12, color: AppColors.grey500),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.grey500),
        ),
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

  final FaIconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.grey200,
          ),
        ),
        child: Row(
          children: [
            FaIcon(
              icon,
              size: 13,
              color: isSelected ? AppColors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.white : AppColors.black,
                ),
              ),
            ),
          ],
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
