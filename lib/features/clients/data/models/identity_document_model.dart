import 'package:easy_localization/easy_localization.dart';
import 'dart:io';

enum DocumentSlot { recto, verso, photo }

extension DocumentSlotExt on DocumentSlot {
  String get label {
    switch (this) {
      case DocumentSlot.recto:
        return 'document_slot.recto'.tr();
      case DocumentSlot.verso:
        return 'document_slot.verso'.tr();
      case DocumentSlot.photo:
        return 'document_slot.photo'.tr();
    }
  }

  String get hint {
    switch (this) {
      case DocumentSlot.recto:
        return 'document_slot.scan_or_gallery'.tr();
      case DocumentSlot.verso:
        return 'document_slot.scan_or_gallery'.tr();
      case DocumentSlot.photo:
        return 'document_slot.camera_only'.tr();
    }
  }
}

class IdentityDocumentModel {
  final DocumentSlot slot;
  final File file;

  const IdentityDocumentModel({required this.slot, required this.file});
}
