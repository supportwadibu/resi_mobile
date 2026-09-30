import 'dart:io';

import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:image_picker/image_picker.dart';

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

    final t = context.tokens;
    return Material(
      color: t.background,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
        side: BorderSide(color: file == null ? t.border : t.primary),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _pick(context),
        child: SizedBox(
          height: 120,
          child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.camera,
                      color: context.tokens.muted,
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(label, style: context.text.bodySmall),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(file), fit: BoxFit.cover),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Tooltip(
                        message: 'Retirer',
                        child: Material(
                          color: t.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.sm,
                            side: BorderSide(color: t.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => onChanged(null),
                            child: SizedBox.square(
                              dimension: 28,
                              child: Icon(
                                LucideIcons.trash2,
                                size: 14,
                                color: t.danger,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
