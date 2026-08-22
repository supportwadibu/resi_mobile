import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import '../../../data/models/identity_document_model.dart';
import 'document_source_sheet.dart';

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
    final hasFile = document != null;

    return GestureDetector(
      onTap: () => _pick(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 165,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasFile
                ? AppColors.green.withOpacity(0.5)
                : AppColors.divider,
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
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

  IconData get _icon {
    switch (slot) {
      case DocumentSlot.recto:
        return Icons.credit_card_rounded;
      case DocumentSlot.verso:
        return Icons.flip_rounded;
      case DocumentSlot.photo:
        return Icons.face_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_icon, size: 30, color: AppColors.textSecondary.withOpacity(0.5)),
        const SizedBox(height: 8),
        Text(
          slot.label,
          style: AppTextStyles.valueSmall.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(slot.hint, style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(document.file, fit: BoxFit.cover),
        // overlay bas
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: Colors.black.withOpacity(0.45),
            child: Text(
              document.slot.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
        // bouton supprimer
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // badge succès
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
