import 'dart:io';

enum DocumentSlot { recto, verso, photo }

extension DocumentSlotExt on DocumentSlot {
  String get label {
    switch (this) {
      case DocumentSlot.recto:
        return 'Recto CNI';
      case DocumentSlot.verso:
        return 'Verso CNI';
      case DocumentSlot.photo:
        return 'Photo identité';
    }
  }

  String get hint {
    switch (this) {
      case DocumentSlot.recto:
        return 'Scan ou galerie';
      case DocumentSlot.verso:
        return 'Scan ou galerie';
      case DocumentSlot.photo:
        return 'Appareil photo uniquement';
    }
  }
}

class IdentityDocumentModel {
  final DocumentSlot slot;
  final File file;

  const IdentityDocumentModel({required this.slot, required this.file});
}
