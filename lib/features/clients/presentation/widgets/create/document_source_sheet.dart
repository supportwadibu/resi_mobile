import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import '../../../data/models/identity_document_model.dart';

class DocumentSourceSheet extends StatelessWidget {
  final DocumentSlot slot;

  const DocumentSourceSheet({super.key, required this.slot});

  static Future<ImagePickerSource?> show(
    BuildContext context,
    DocumentSlot slot,
  ) {
    return showModalBottomSheet<ImagePickerSource>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DocumentSourceSheet(slot: slot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cameraOnly = slot == DocumentSlot.photo;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(slot.label, style: AppTextStyles.sectionTitle),
            const SizedBox(height: 6),
            Text(
              slot.hint,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _SourceTile(
              icon: Icons.camera_alt_rounded,
              label: 'Prendre une photo',
              onTap: () => Navigator.pop(context, ImagePickerSource.camera),
            ),
            if (!cameraOnly) ...[
              const SizedBox(height: 10),
              _SourceTile(
                icon: Icons.photo_library_rounded,
                label: 'Choisir depuis la galerie',
                onTap: () => Navigator.pop(context, ImagePickerSource.gallery),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

enum ImagePickerSource { camera, gallery }

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.green),
            const SizedBox(width: 14),
            Text(label, style: AppTextStyles.valueSmall),
          ],
        ),
      ),
    );
  }
}
