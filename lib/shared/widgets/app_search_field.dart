import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/resi_tokens.dart';

/// Faux champ de recherche qui ouvre l'écran de recherche au toucher, avec la
/// loupe à gauche comme l'`Input type="search"` du backoffice.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    required this.onTap,
    this.hint,
    this.padding,
    super.key,
  });

  final VoidCallback onTap;
  final String? hint;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Material(
        color: t.background,
        shape: AppRadius.outlined(AppRadius.md, t.border),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 44,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(LucideIcons.search, size: 16, color: t.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hint ?? 'common.search_ellipsis'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium!.copyWith(color: t.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
