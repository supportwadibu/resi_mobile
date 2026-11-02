import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';

import '../../../data/services/id_card_reading.dart';
import '../../../data/services/id_scan_service.dart';

/// Lit une pièce d'identité et préremplit ce qu'elle porte.
///
/// Deux entrées, parce que ML Kit analyse une image sans piloter l'appareil
/// photo :
///
/// - **scanner** : l'appareil photo s'ouvre, la lecture part seule au retour ;
/// - **importer** : une photo déjà prise, choisie dans la galerie.
///
/// [onScanned] reçoit le chemin de la photo — qui devient une face de la
/// pièce — et ce qui a pu être lu, `null` si rien. Les champs non lus restent
/// à saisir, et tout reste modifiable, maintenant ou depuis la fiche.
class IdScanButton extends StatefulWidget {
  const IdScanButton({required this.onScanned, super.key});

  final void Function(String imagePath, IdCardReading? reading) onScanned;

  @override
  State<IdScanButton> createState() => _IdScanButtonState();
}

class _IdScanButtonState extends State<IdScanButton> {
  bool _scanning = false;

  Future<void> _scan() async {
    final source = await showAppSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => AppSheet(
        title: 'ocr.source_title'.tr(),
        description: 'ocr.hint'.tr(),
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          children: [
            AppSheetAction(
              icon: LucideIcons.scanText,
              label: 'ocr.source_camera'.tr(),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            AppSheetAction(
              icon: LucideIcons.images,
              label: 'ocr.source_gallery'.tr(),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final photo = await ImagePicker().pickImage(
      source: source,
      // Assez fin pour la MRZ, assez léger pour l'envoi sur un réseau lent.
      maxWidth: 2000,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;

    setState(() => _scanning = true);
    final reading = await const IdScanService().scan(photo.path);
    if (!mounted) return;
    setState(() => _scanning = false);

    widget.onScanned(photo.path, reading);
    if (reading == null) {
      AppToast.warning('ocr.not_found'.tr(), context: context);
    } else {
      AppToast.success('ocr.found'.tr(), context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: (_scanning ? 'ocr.scanning' : 'ocr.scan').tr(),
          icon: LucideIcons.scanText,
          variant: AppButtonVariant.secondary,
          isLoading: _scanning,
          expand: true,
          onPressed: _scanning ? null : _scan,
        ),
        const SizedBox(height: 6),
        Text('ocr.hint'.tr(), style: context.text.bodySmall),
      ],
    );
  }
}
