import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_badge.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import '../../../../clients/presentation/widgets/client_avatar.dart';

import '../../../../clients/data/models/client_model.dart';

/// Bloc d'identification du client : fiche choisie au carnet, ou saisie.
///
/// La recherche par numéro tourne pendant la frappe ; quand elle trouve une
/// fiche, [duplicate] la propose plutôt que de créer un doublon — le téléphone
/// identifie le client, et un doublon fausserait ses statistiques de séjour.
class ClientFieldGroup extends StatelessWidget {
  const ClientFieldGroup({
    required this.selected,
    required this.nameController,
    required this.phoneController,
    required this.onNameChanged,
    required this.onPhoneChanged,
    this.onPickFromBook,
    required this.onClearSelection,
    required this.duplicate,
    required this.onUseDuplicate,
    required this.onDismissDuplicate,
    this.isLookingUp = false,
    super.key,
  });

  final ClientModel? selected;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPhoneChanged;

  /// `null` : le carnet n'est pas consultable — forfait 3 000 F. Le bouton
  /// disparaît, et la recherche par numéro retrouve encore un habitué.
  final VoidCallback? onPickFromBook;
  final VoidCallback onClearSelection;

  final ClientModel? duplicate;
  final ValueChanged<ClientModel> onUseDuplicate;
  final VoidCallback onDismissDuplicate;
  final bool isLookingUp;

  @override
  Widget build(BuildContext context) {
    if (selected != null) {
      return _SelectedClientCard(client: selected!, onChange: onClearSelection);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onPickFromBook != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppButton(
              label: 'booking_form.pick_from_book'.tr(),
              icon: LucideIcons.contact,
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: onPickFromBook,
            ),
          ),
        _Field(
          controller: nameController,
          hint: 'booking_form.name_hint'.tr(),
          onChanged: onNameChanged,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: phoneController,
          hint: 'booking_form.phone_placeholder'.tr(),
          keyboardType: TextInputType.phone,
          onChanged: onPhoneChanged,
          suffix: isLookingUp
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: AppLoader(size: 20),
                )
              : null,
        ),
        if (duplicate != null) ...[
          const SizedBox(height: 10),
          _DuplicateBanner(
            client: duplicate!,
            onUse: () => onUseDuplicate(duplicate!),
            onDismiss: onDismissDuplicate,
          ),
        ],
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: context.text.bodyMedium,
      decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
    );
  }
}

/// Fiche retenue, avec de quoi en changer.
class _SelectedClientCard extends StatelessWidget {
  const _SelectedClientCard({required this.client, required this.onChange});

  final ClientModel client;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClientAvatar(initials: client.avatarInitials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.fullName,
                  style: context.text.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(client.phone, style: context.text.bodySmall),
                if (!client.documentsComplete) ...[
                  const SizedBox(height: 4),
                  AppBadge(
                    label: 'booking_form.id_incomplete'.tr(),
                    tone: AppAccent.amber,
                  ),
                ],
              ],
            ),
          ),
          AppButton(
            label: 'stats.change'.tr(),
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            onPressed: onChange,
          ),
        ],
      ),
    );
  }
}

/// Fiche trouvée au numéro saisi, proposée à la réutilisation.
class _DuplicateBanner extends StatelessWidget {
  const _DuplicateBanner({
    required this.client,
    required this.onUse,
    required this.onDismiss,
  });

  final ClientModel client;
  final VoidCallback onUse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppCallout(
      icon: LucideIcons.userSearch,
      tone: AppAccent.amber,
      title: 'booking_form.number_in_book'.tr(),
      message: client.fullName,
      action: Row(
        children: [
          AppButton(
            label: 'booking_form.use_record'.tr(),
            size: AppButtonSize.sm,
            onPressed: onUse,
          ),
          const SizedBox(width: 8),
          AppButton(
            label: 'booking_form.new_client'.tr(),
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
