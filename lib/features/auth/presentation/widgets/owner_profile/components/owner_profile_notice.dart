import 'package:flutter/material.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';

/// Encart d'information ou d'alerte du dossier de validation.
///
/// Le ton suit la grammaire des statuts : bleu pris en compte, vert validé,
/// rouge refusé ou suspendu.
class OwnerProfileNotice extends StatelessWidget {
  const OwnerProfileNotice({
    super.key,
    required this.icon,
    required this.tone,
    required this.message,
  });

  final IconData icon;
  final AppAccent tone;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCallout(icon: icon, tone: tone, message: message);
  }
}
