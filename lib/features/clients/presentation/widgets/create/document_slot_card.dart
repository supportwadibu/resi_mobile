import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resi_africa/shared/widgets/app_badge.dart';
import '../../../data/models/identity_document_model.dart';
import 'document_source_sheet.dart';

/// Emplacement d'une pièce (recto, verso, photo) : vide, il invite à prendre
/// la photo ; rempli, il montre l'aperçu avec de quoi le retirer.
class DocumentSlotCard extends StatelessWidget {
  final DocumentSlot slot;
  final IdentityDocumentModel? document;
  final ValueChanged<File> onPicked;
  final VoidCallback onRemove;

  const DocumentSlotCard({
    super.key,
    required this.slot,
    required this.document,
    required this.onPicked,
    required this.onRemove,
  });

  Future<void> _pick(BuildContext context) async {
    final source = await DocumentSourceSheet.show(context, slot);
    if (source == null) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source == ImagePickerSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) onPicked(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasFile = document != null;

    return Material(
      color: t.background,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
        side: BorderSide(color: hasFile ? t.primary : t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _pick(context),
        child: SizedBox(
          height: 160,
          width: double.infinity,
          child: hasFile
              ? _FilledSlot(document: document!, onRemove: onRemove)
              : _EmptySlot(slot: slot),
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final DocumentSlot slot;
  const _EmptySlot({required this.slot});

  IconData get _icon => switch (slot) {
    DocumentSlot.recto => LucideIcons.creditCard,
    DocumentSlot.verso => LucideIcons.flipHorizontal,
    DocumentSlot.photo => LucideIcons.user,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_icon, size: 24, color: context.tokens.muted),
        const SizedBox(height: 8),
        Text(slot.label, style: context.text.titleSmall),
        const SizedBox(height: 2),
        Text(slot.hint, style: context.text.bodySmall),
      ],
    );
  }
}

class _FilledSlot extends StatelessWidget {
  final IdentityDocumentModel document;
  final VoidCallback onRemove;

  const _FilledSlot({required this.document, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(document.file, fit: BoxFit.cover),
        // Libellé sur un voile : `overlay` / `onOverlay`, identiques dans les
        // deux modes, la photo ne changeant pas.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: t.overlay.withValues(alpha: 0.55),
            child: Text(
              document.slot.label,
              style: context.text.bodySmall!.copyWith(color: t.onOverlay),
            ),
          ),
        ),
        const Positioned(
          top: 6,
          left: 6,
          child: AppBadge(
            label: 'Ajoutée',
            tone: AppAccent.green,
            icon: LucideIcons.check,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
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
                onTap: onRemove,
                child: SizedBox.square(
                  dimension: 32,
                  child: Icon(LucideIcons.trash2, size: 14, color: t.danger),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
