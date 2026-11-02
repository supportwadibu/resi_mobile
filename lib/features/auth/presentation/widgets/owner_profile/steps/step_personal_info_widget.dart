import 'package:easy_localization/easy_localization.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
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
    if (value == null || value.trim().isEmpty) {
      return 'common.field_required'.tr();
    }
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
            OwnerProfileNotice(
              icon: LucideIcons.idCard,
              tone: AppAccent.blue,
              message: 'owner_profile.intro'.tr(),
            ),
            const SizedBox(height: 24),
          ],

          if (profile != null) ...[?_buildStatusNotice(context, profile!)],

          Text(
            'owner_profile.who_are_you'.tr(),
            style: context.text.titleMedium,
          ),
          const SizedBox(height: 20),

          AppTextField(
            label: 'owner_profile.full_name'.tr(),
            hint: 'owner_profile.full_name_hint'.tr(),
            controller: nameController,
            prefixIcon: const Icon(LucideIcons.user, size: 16),
            validator: _required,
          ),

          const SizedBox(height: 24),
          Text(
            'owner_profile.where_do_you_live'.tr(),
            style: context.text.titleMedium,
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
            label: 'owner_profile.address'.tr(),
            hint: 'owner_profile.address_hint'.tr(),
            controller: addressController,
            prefixIcon: const Icon(LucideIcons.mapPin, size: 16),
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
  Widget? _buildStatusNotice(BuildContext context, OwnerProfileModel profile) {
    final notice = switch (profile) {
      _ when profile.isRejected => OwnerProfileNotice(
        icon: LucideIcons.circleAlert,
        tone: AppAccent.red,
        message:
            profile.rejectionReason == null || profile.rejectionReason!.isEmpty
            ? 'owner_profile.rejected'.tr()
            : 'owner_profile.rejected_with_reason'.tr(
                args: [profile.rejectionReason!],
              ),
      ),
      _ when profile.isSuspended => OwnerProfileNotice(
        icon: LucideIcons.ban,
        tone: AppAccent.red,
        message: 'owner_profile.suspended'.tr(),
      ),
      _ when profile.isUnderReview => OwnerProfileNotice(
        icon: LucideIcons.clock,
        tone: AppAccent.blue,
        message: 'owner_profile.under_review'.tr(),
      ),
      _ when profile.isValidated => OwnerProfileNotice(
        icon: LucideIcons.circleCheck,
        tone: AppAccent.green,
        message: 'owner_profile.validated'.tr(),
      ),
      _ => null,
    };

    if (notice == null) return null;
    return Padding(padding: const EdgeInsets.only(bottom: 24), child: notice);
  }
}
