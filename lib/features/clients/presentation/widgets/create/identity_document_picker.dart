import 'dart:io';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
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
        _DocumentProgress(
          total: DocumentSlot.values.length,
          filled: documents.length,
        ),
        const SizedBox(height: 12),

        ...DocumentSlot.values.map(
          (slot) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
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
            style: context.text.bodySmall!.copyWith(
              color: context.tokens.accentRed,
            ),
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
          child: LinearProgressIndicator(
            value: filled / total,
            minHeight: 4,
            color: filled == total
                ? context.tokens.accentGreen
                : context.tokens.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$filled / $total',
          style: context.text.bodySmall!.copyWith(
            color: filled == total
                ? context.tokens.accentGreen
                : context.tokens.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
