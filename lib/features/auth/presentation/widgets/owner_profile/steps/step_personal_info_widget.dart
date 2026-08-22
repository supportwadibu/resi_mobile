import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/app_city_field.dart';
import 'package:resi_africa/shared/widgets/app_commune_field.dart';
import 'package:resi_africa/shared/widgets/app_country_field.dart';
import 'package:resi_africa/shared/widgets/app_phone_field.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';

import '../../../../data/models/owner_profile_model.dart';
import '../components/owner_profile_header.dart';
import '../components/owner_profile_notice.dart';

/// Étape 1 du dossier de validation : identité civile et coordonnées.
///
/// La localisation se renseigne dans l'ordre pays → ville → téléphone : le
/// pays détermine la liste des villes et l'indicatif téléphonique, les deux
/// champs suivants n'ayant pas de sens avant lui.
class StepPersonalInfoWidget extends StatelessWidget {
  const StepPersonalInfoWidget({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.cityController,
    required this.communeController,
    required this.city,
    required this.onCityChanged,
    required this.country,
    required this.onCountryChanged,
    this.profile,
    this.showIntro = false,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController communeController;

  /// Ville retenue, remontée au parent pour que le champ commune se recharge :
  /// un `TextEditingController` seul ne déclencherait pas de reconstruction.
  final String city;
  final ValueChanged<String> onCityChanged;

  /// Pays retenu, jamais nul : la Côte d'Ivoire sert de valeur par défaut.
  final Country country;
  final ValueChanged<Country> onCountryChanged;

  /// Dossier tel que renvoyé par l'API. Nul tant qu'aucun n'a été chargé —
  /// première inscription, ou lecture impossible hors ligne.
  final OwnerProfileModel? profile;

  /// Rappelle l'enjeu de la démarche pendant l'inscription uniquement.
  final bool showIntro;

  static String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ce champ est requis';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identité réelle du gestionnaire, hors inscription : pendant
          // l'onboarding le dossier est vide, l'en-tête n'aurait rien à
          // montrer.
          if (!showIntro && profile != null) ...[
            OwnerProfileHeader(profile: profile!),
            const SizedBox(height: 24),
          ],

          if (showIntro) ...[
            const OwnerProfileNotice(
              icon: FontAwesomeIcons.idCard,
              color: AppColors.info,
              background: AppColors.infoBg,
              message:
                  'Ces informations permettent de valider votre compte. '
                  'Sans dossier validé, votre accès sera suspendu à la fin de '
                  'l’essai gratuit.',
            ),
            const SizedBox(height: 24),
          ],

          if (profile != null) ...[
            ?_buildStatusNotice(profile!),
          ],

          const Text(
            'Qui êtes-vous ?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          AppTextField(
            label: 'Nom complet',
            hint: 'Tel qu’il figure sur votre pièce d’identité',
            controller: nameController,
            prefixIcon: const Icon(Icons.person_outline, size: 18),
            validator: _required,
          ),

          const SizedBox(height: 24),
          const Text(
            'Où résidez-vous ?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          // ── Pays d'abord : il conditionne la ville et l'indicatif.
          AppCountryField(country: country, onSelected: onCountryChanged),
          const SizedBox(height: 16),

          // ── Puis la ville, rechargée à chaque changement de pays.
          AppCityField(
            countryIso2: country.countryCode,
            controller: cityController,
            onChanged: onCityChanged,
            validator: _required,
          ),

          // ── Enfin la commune, si la ville en possède. Le widget se masque
          // de lui-même dans le cas contraire, d'où l'absence d'espacement
          // ici : il le porte lui-même.
          AppCommuneField(
            countryIso2: country.countryCode,
            city: city,
            controller: communeController,
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: 'Adresse',
            hint: 'Rue, quartier...',
            controller: addressController,
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
          ),

          const SizedBox(height: 24),
          // ── Enfin le téléphone, dont l'indicatif découle du pays.
          AppPhoneField(
            countryIso2: country.countryCode,
            phoneCode: country.phoneCode,
            controller: phoneController,
          ),
        ],
      ),
    );
  }

  /// Encart d'état du dossier, ou `null` quand rien n'appelle de commentaire.
  ///
  /// Le motif de refus et l'échéance de suspension viennent du serveur : les
  /// afficher tels quels évite d'inventer une explication que l'utilisateur ne
  /// pourrait pas relier à la décision réelle.
  Widget? _buildStatusNotice(OwnerProfileModel profile) {
    final notice = switch (profile) {
      _ when profile.isRejected => OwnerProfileNotice(
        icon: FontAwesomeIcons.circleExclamation,
        color: AppColors.error,
        background: AppColors.errorBg,
        message:
            profile.rejectionReason == null ||
                profile.rejectionReason!.isEmpty
            ? 'Votre dossier a été refusé. Corrigez-le et renvoyez-le.'
            : 'Dossier refusé : ${profile.rejectionReason}',
      ),
      _ when profile.isSuspended => const OwnerProfileNotice(
        icon: FontAwesomeIcons.ban,
        color: AppColors.error,
        background: AppColors.errorBg,
        message:
            'Votre compte est suspendu faute de dossier validé. '
            'Complétez-le pour retrouver l’accès à vos biens.',
      ),
      _ when profile.isUnderReview => const OwnerProfileNotice(
        icon: FontAwesomeIcons.clock,
        color: AppColors.info,
        background: AppColors.infoBg,
        message:
            'Votre dossier est en cours de vérification. '
            'Vous pouvez encore le corriger tant qu’il n’est pas validé.',
      ),
      _ when profile.isValidated => const OwnerProfileNotice(
        icon: FontAwesomeIcons.circleCheck,
        color: AppColors.success,
        background: AppColors.successBg,
        message: 'Votre dossier est validé. Vos informations restent modifiables.',
      ),
      _ => null,
    };

    if (notice == null) return null;
    return Padding(padding: const EdgeInsets.only(bottom: 24), child: notice);
  }
}
