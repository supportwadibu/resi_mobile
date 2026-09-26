import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';

class ClientSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const ClientSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: context.text.bodyMedium,
      decoration: const InputDecoration(
        hintText: 'Rechercher par nom ou téléphone',
        prefixIcon: Icon(LucideIcons.search, size: 16),
      ),
    );
  }
}
