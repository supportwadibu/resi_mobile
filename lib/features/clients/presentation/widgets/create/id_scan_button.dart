import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';

import '../../../data/services/id_scan_service.dart';
import '../../../data/services/mrz_parser.dart';

/// Photographie le verso de la pièce et en lit la bande MRZ.
///
/// [onScanned] reçoit le chemin de la photo — qui devient la face arrière de
/// la pièce — et ce qui a pu être lu, `null` si rien. Les champs non lus
/// restent à saisir, maintenant ou plus tard depuis la fiche client.
class IdScanButton extends StatefulWidget {
  const IdScanButton({required this.onScanned, super.key});

  final void Function(String imagePath, MrzResult? result) onScanned;

  @override
  State<IdScanButton> createState() => _IdScanButtonState();
}

class _IdScanButtonState extends State<IdScanButton> {
  bool _scanning = false;

  Future<void> _scan() async {
    final messenger = ScaffoldMessenger.of(context);
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      // Assez fin pour la MRZ, assez léger pour l'envoi sur un réseau lent.
      maxWidth: 2000,
      imageQuality: 85,
    );
    if (photo == null || !mounted) return;

    setState(() => _scanning = true);
    final result = await const IdScanService().scan(photo.path);
    if (!mounted) return;
    setState(() => _scanning = false);

    widget.onScanned(photo.path, result);
    messenger.showSnackBar(
      SnackBar(
        content: Text((result == null ? 'ocr.not_found' : 'ocr.found').tr()),
      ),
    );
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
          onPressed: _scan,
        ),
        const SizedBox(height: 6),
        Text('ocr.hint'.tr(), style: context.text.bodySmall),
      ],
    );
  }
}
