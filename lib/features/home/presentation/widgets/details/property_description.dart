import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

/// Description libre saisie par le propriétaire.
class PropertyDescription extends StatelessWidget {
  const PropertyDescription({super.key, required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    if (description.trim().isEmpty) return const SizedBox.shrink();

    return Section(
      title: 'Description',
      icon: LucideIcons.alignLeft,
      child: Text(description, style: context.mutedText.copyWith(height: 1.55)),
    );
  }
}
