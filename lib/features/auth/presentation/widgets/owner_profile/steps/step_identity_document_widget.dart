import 'dart:io';

import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_option_tile.dart';
import 'package:resi_africa/shared/widgets/app_text_field.dart';

import '../../../../data/models/owner_profile_model.dart';

/// Étape 2 du dossier de validation : nature de la pièce et justificatifs.
class StepIdentityDocumentWidget extends StatelessWidget {
  const StepIdentityDocumentWidget({
    super.key,
    required this.formKey,
    required this.idNumberController,
    required this.documentType,
    required this.onDocumentTypeChanged,
    required this.frontImagePath,
    required this.frontRemoteUrl,
    required this.onPickFront,
    required this.backImagePath,
    required this.backRemoteUrl,
    required this.onPickBack,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController idNumberController;

  final IdDocumentType? documentType;
  final void Function(IdDocumentType?) onDocumentTypeChanged;

  final String? frontImagePath;
  final String? frontRemoteUrl;
  final VoidCallback onPickFront;

  final String? backImagePath;
  final String? backRemoteUrl;
  final VoidCallback onPickBack;

  bool get _backRequired => documentType?.requiresBack ?? false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quelle pièce d’identité fournissez-vous ?',
            style: context.text.titleMedium,
          ),
          const SizedBox(height: 20),

          _buildDocumentTypeSelector(),
          const SizedBox(height: 20),

          AppTextField(
            label: 'Numéro de la pièce',
            hint: 'Tel qu’inscrit sur le document',
            controller: idNumberController,
            prefixIcon: const Icon(LucideIcons.idCard, size: 16),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ce champ est requis';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),
          _UploadField(
            title: 'Recto de la pièce',
            localPath: frontImagePath,
            remoteUrl: frontRemoteUrl,
            onTap: onPickFront,
          ),
          if (_backRequired) ...[
            const SizedBox(height: 16),
            _UploadField(
              title: 'Verso de la pièce',
              localPath: backImagePath,
              remoteUrl: backRemoteUrl,
              onTap: onPickBack,
            ),
          ],
        ],
      ),
    );
  }

  /// Sélection par cartes plutôt que par menu déroulant : trois options
  /// seulement, et l'exigence de verso doit être visible avant le choix.
  Widget _buildDocumentTypeSelector() {
    return Column(
      children: [
        for (final type in IdDocumentType.values) ...[
          AppOptionTile(
            icon: _iconFor(type),
            title: type.label,
            description: type.requiresBack
                ? 'Recto et verso requis'
                : 'Page de données uniquement',
            selected: documentType == type,
            onTap: () => onDocumentTypeChanged(type),
          ),
          if (type != IdDocumentType.values.last) const SizedBox(height: 8),
        ],
      ],
    );
  }

  static IconData _iconFor(IdDocumentType type) => switch (type) {
    IdDocumentType.cni => LucideIcons.idCard,
    IdDocumentType.passport => LucideIcons.bookUser,
    IdDocumentType.drivingLicence => LucideIcons.idCard,
  };
}

/// Zone de dépôt d'un justificatif.
///
/// Trois états : image choisie sur l'appareil, image déjà transmise au serveur
/// (URL signée), ou emplacement vide.
class _UploadField extends StatelessWidget {
  const _UploadField({
    required this.title,
    required this.localPath,
    required this.remoteUrl,
    required this.onTap,
  });

  final String title;
  final String? localPath;
  final String? remoteUrl;
  final VoidCallback onTap;

  bool get _hasImage => localPath != null || remoteUrl != null;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleSmall),
        const SizedBox(height: 6),
        Material(
          color: t.background,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.md,
            side: BorderSide(color: _hasImage ? t.primary : t.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 170,
              width: double.infinity,
              child: _buildPreview(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    // Une image choisie via `ImagePicker` est un fichier de l'appareil, jamais
    // un asset empaqueté : `Image.file` est le seul chargeur qui sache la lire.
    if (localPath != null) {
      return Image.file(
        File(localPath!),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    if (remoteUrl != null) {
      return Image.network(
        remoteUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        // L'URL est signée et temporaire : son expiration ne doit pas casser
        // l'écran, l'utilisateur peut toujours redéposer le fichier.
        errorBuilder: (context, _, _) => _placeholder(
          context,
          'Aperçu indisponible · appuyez pour remplacer',
        ),
      );
    }

    return _placeholder(context, 'Appuyez pour ajouter une photo');
  }

  Widget _placeholder(BuildContext context, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.cloudUpload, size: 24, color: context.tokens.muted),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: context.text.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(
          'Photo nette, document entier visible',
          style: context.text.bodySmall,
        ),
      ],
    );
  }
}
