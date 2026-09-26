import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import '../../../data/models/identity_document_model.dart';

/// Choix de la source d'une pièce : appareil photo ou galerie.
class DocumentSourceSheet extends StatelessWidget {
  final DocumentSlot slot;

  const DocumentSourceSheet({super.key, required this.slot});

  static Future<ImagePickerSource?> show(
    BuildContext context,
    DocumentSlot slot,
  ) {
    return showAppSheet<ImagePickerSource>(
      context: context,
      builder: (_) => DocumentSourceSheet(slot: slot),
    );
  }

  @override
  Widget build(BuildContext context) {
    // La photo du client se prend sur place : la galerie ouvrirait la porte à
    // une image sans rapport avec la personne au comptoir.
    final cameraOnly = slot == DocumentSlot.photo;

    return AppSheet(
      title: slot.label,
      description: slot.hint,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          AppSheetAction(
            icon: LucideIcons.camera,
            label: 'Prendre une photo',
            onTap: () => Navigator.pop(context, ImagePickerSource.camera),
          ),
          if (!cameraOnly)
            AppSheetAction(
              icon: LucideIcons.images,
              label: 'Choisir depuis la galerie',
              onTap: () => Navigator.pop(context, ImagePickerSource.gallery),
            ),
        ],
      ),
    );
  }
}

enum ImagePickerSource { camera, gallery }
