import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

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
    required this.onPickFromBook,
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
  final VoidCallback onPickFromBook;
  final VoidCallback onClearSelection;

  final ClientModel? duplicate;
  final ValueChanged<ClientModel> onUseDuplicate;
  final VoidCallback onDismissDuplicate;
  final bool isLookingUp;

  @override
  Widget build(BuildContext context) {
    if (selected != null) {
      return _SelectedClientCard(
        client: selected!,
        onChange: onClearSelection,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onPickFromBook,
            icon: const Icon(Icons.contacts_outlined, size: 16),
            label: const Text(
              'Choisir un client',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(height: 4),
        _Field(
          controller: nameController,
          hint: 'Nom et prénoms — ex : Mohamed Traoré',
          onChanged: onNameChanged,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        _Field(
          controller: phoneController,
          hint: '+225 07 XX XX XX XX',
          keyboardType: TextInputType.phone,
          onChanged: onPhoneChanged,
          suffix: isLookingUp
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
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
      style: const TextStyle(fontSize: 13.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              client.avatarInitials,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  client.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (!client.documentsComplete) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Pièce d’identité incomplète',
                    style: TextStyle(fontSize: 11, color: AppColors.warning),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Changer', style: TextStyle(fontSize: 12.5)),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Ce numéro est déjà au carnet : '),
                  TextSpan(
                    text: client.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: onUse,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('Utiliser', style: TextStyle(fontSize: 12.5)),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.grey500,
            visualDensity: VisualDensity.compact,
            tooltip: 'Créer un nouveau client',
          ),
        ],
      ),
    );
  }
}
