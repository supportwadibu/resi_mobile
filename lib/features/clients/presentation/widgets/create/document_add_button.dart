import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/theme/app_typography.dart';

class DocumentAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const DocumentAddButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.background,
      shape: RoundedRectangleBorder(side: BorderSide(color: t.border)),
      child: InkWell(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 90,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.plus, size: 20, color: t.muted),
              const SizedBox(height: 4),
              Text('Ajouter', style: context.text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
