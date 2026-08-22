import 'dart:io';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/theme/app_text_styles.dart';
import '../../../data/models/identity_document_model.dart';
import 'document_slot_card.dart';

class IdentityDocumentPicker extends StatelessWidget {
  final Map<DocumentSlot, IdentityDocumentModel> documents;
  final void Function(DocumentSlot slot, File file) onAdd;
  final ValueChanged<DocumentSlot> onRemove;
  final bool showError;

  const IdentityDocumentPicker({
    super.key,
    required this.documents,
    required this.onAdd,
    required this.onRemove,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    final missing = DocumentSlot.values
        .where((s) => !documents.containsKey(s))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator
        _DocumentProgress(
          total: DocumentSlot.values.length,
          filled: documents.length,
        ),
        const SizedBox(height: 14),

        // 3 slots
        ...DocumentSlot.values.map(
          (slot) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DocumentSlotCard(
              slot: slot,
              document: documents[slot],
              onPicked: (file) => onAdd(slot, file),
              onRemove: () => onRemove(slot),
            ),
          ),
        ),

        if (showError && missing > 0)
          Text(
            '$missing document${missing > 1 ? 's' : ''} manquant${missing > 1 ? 's' : ''}',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.red),
          ),
      ],
    );
  }
}

class _DocumentProgress extends StatelessWidget {
  final int total;
  final int filled;

  const _DocumentProgress({required this.total, required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: filled / total,
              minHeight: 4,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$filled / $total',
          style: AppTextStyles.labelSmall.copyWith(
            color: filled == total ? AppColors.green : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
