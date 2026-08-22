import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
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
          const Text(
            'Quelle pièce d’identité fournissez-vous ?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          _buildDocumentTypeSelector(),
          const SizedBox(height: 20),

          AppTextField(
            label: 'Numéro de la pièce',
            hint: 'Tel qu’inscrit sur le document',
            controller: idNumberController,
            prefixIcon: const Icon(Icons.badge_outlined, size: 18),
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
          GestureDetector(
            onTap: () => onDocumentTypeChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: documentType == type
                    ? AppColors.black
                    : AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: documentType == type
                      ? AppColors.black
                      : AppColors.grey200,
                  width: documentType == type ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  FaIcon(
                    _iconFor(type),
                    size: 18,
                    color: documentType == type
                        ? AppColors.white
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: documentType == type
                                ? AppColors.white
                                : AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          type.requiresBack
                              ? 'Recto et verso requis'
                              : 'Page de données uniquement',
                          style: TextStyle(
                            fontSize: 11,
                            color: documentType == type
                                ? AppColors.white.withValues(alpha: 0.7)
                                : AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (documentType == type)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.white,
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
          if (type != IdDocumentType.values.last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  static FaIconData _iconFor(IdDocumentType type) => switch (type) {
    IdDocumentType.cni => FontAwesomeIcons.idCard,
    IdDocumentType.passport => FontAwesomeIcons.passport,
    IdDocumentType.drivingLicence => FontAwesomeIcons.idBadge,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _hasImage
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hasImage ? AppColors.primary : AppColors.grey200,
                width: _hasImage ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildPreview(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
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
        errorBuilder: (_, _, _) =>
            _placeholder('Aperçu indisponible · appuyez pour remplacer'),
      );
    }

    return _placeholder('Appuyez pour ajouter une photo');
  }

  Widget _placeholder(String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const FaIcon(
          FontAwesomeIcons.cloudArrowUp,
          size: 28,
          color: AppColors.grey400,
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Photo nette, document entier visible',
          style: TextStyle(fontSize: 12, color: AppColors.grey500),
        ),
      ],
    );
  }
}
