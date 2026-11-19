import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/rapport/data/models/report_type_model.dart';
import 'package:resi_africa/shared/widgets/stat_tile.dart';

/// Types de rapport en grille de tuiles : la choisie en lavande, les autres
/// neutres — la grammaire des tuiles de l'accueil.
class ReportTypeSelector extends StatelessWidget {
  final ReportType selected;
  final ValueChanged<ReportType> onChanged;

  const ReportTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _icons = {
    ReportType.financial: LucideIcons.trendingUp,
    ReportType.performance: LucideIcons.chartColumn,
    ReportType.reservations: LucideIcons.users,
    ReportType.police: LucideIcons.shield,
  };

  @override
  Widget build(BuildContext context) {
    final types = ReportType.values;
    return Column(
      children: [
        for (var i = 0; i < types.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _tile(types[i])),
              const SizedBox(width: 10),
              Expanded(
                child: i + 1 < types.length
                    ? _tile(types[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _tile(ReportType type) => _TypeTile(
    icon: _icons[type]!,
    title: type.label,
    description: type.description,
    selected: type == selected,
    onTap: () => onChanged(type),
  );
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final fg = selected ? t.onLavender : t.foreground;
    final body = SizedBox(
      height: 150,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: selected ? t.onOverlay : t.background,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension: 40,
                    child: Icon(
                      icon,
                      size: 18,
                      color: selected ? t.onLavender : t.foreground,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    selected ? LucideIcons.circleCheck : LucideIcons.circle,
                    key: ValueKey(selected),
                    size: 20,
                    color: selected ? t.onLavender : t.border,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall!.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall!.copyWith(
                color: fg.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? t.lavender : t.surface,
          borderRadius: AppRadius.lg,
          border: Border.all(color: selected ? t.lavender : t.border),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadius.lg,
            onTap: onTap,
            child: selected
                ? HaloSurface(radius: AppRadius.lg, child: body)
                : body,
          ),
        ),
      ),
    );
  }
}
