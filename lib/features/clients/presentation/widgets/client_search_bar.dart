import 'package:easy_localization/easy_localization.dart';
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
      decoration: InputDecoration(
        hintText: 'clients.search_hint'.tr(),
        prefixIcon: Icon(LucideIcons.search, size: 16),
      ),
    );
  }
}
