import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

import '../../../../clients/data/models/identity_document_model.dart';
import '../../../../clients/presentation/widgets/create/document_source_sheet.dart';

/// Dépôt des deux faces de la pièce d'identité, qui remonte les chemins.
///
/// Les pièces restent facultatives : au comptoir, un client peut ne pas avoir
/// sa pièce sur lui, et bloquer l'enregistrement bloquerait une entrée
/// d'argent. La fiche est alors marquée incomplète, pour relance.
class ReservationDocumentPicker extends StatelessWidget {
  const ReservationDocumentPicker({
    required this.frontPath,
    required this.backPath,
    required this.onFrontChanged,
    required this.onBackChanged,
    super.key,
  });

  final String? frontPath;
  final String? backPath;
  final ValueChanged<String?> onFrontChanged;
  final ValueChanged<String?> onBackChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DocumentSlot(
            label: 'CNI Recto',
            path: frontPath,
            slot: DocumentSlot.recto,
            onChanged: onFrontChanged,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DocumentSlot(
            label: 'CNI Verso',
            path: backPath,
            slot: DocumentSlot.verso,
            onChanged: onBackChanged,
          ),
        ),
      ],
    );
  }
}

class _DocumentSlot extends StatelessWidget {
  const _DocumentSlot({
    required this.label,
    required this.path,
    required this.slot,
    required this.onChanged,
  });

  final String label;
  final String? path;
  final DocumentSlot slot;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final file = path;

    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        height: 120,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file == null ? AppColors.divider : AppColors.primary,
          ),
        ),
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.grey500,
                    size: 22,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(file), fit: BoxFit.cover),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onChanged(null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final source = await DocumentSourceSheet.show(context, slot);
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source == ImagePickerSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      // Les pièces partent en multipart sur un réseau souvent lent : les
      // réduire évite un envoi qui expire.
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (picked != null) onChanged(picked.path);
  }
}
