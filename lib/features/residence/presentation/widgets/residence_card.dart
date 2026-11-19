import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/features/residence/data/models/residence_model.dart';
import 'package:resi_africa/shared/motion/motion.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/shared/widgets/frosted_surface.dart';

/// Une résidence dans la liste, comme les cartes de biens des maquettes :
/// photo encadrée, nombre de logements en pastille de verre, flèche en disque
/// noir, nom et ville dessous.
class ResidenceCard extends StatelessWidget {
  const ResidenceCard({
    super.key,
    required this.residence,
    this.onTap,
    this.onDelete,
  });

  final ResidenceModel residence;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final count = residence.unitsCount;
    final image = residence.images.isEmpty ? null : residence.images.first;
    return PressScale(
      scale: 0.98,
      enabled: onTap != null,
      child: Material(
        color: t.surface,
        shape: AppRadius.outlined(AppRadius.lg, t.border),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.md,
                  child: SizedBox(
                    height: 150,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (image != null)
                          CachedNetworkImage(
                            imageUrl: image,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const _Placeholder(),
                          )
                        else
                          const _Placeholder(),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: _UnitsPill(count: count),
                        ),
                        if (onDelete != null)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: FrostedSurface(
                              borderRadius: FrostedSurface.pill,
                              child: AppIconButton(
                                icon: LucideIcons.trash2,
                                label: 'common.delete'.tr(),
                                danger: true,
                                onPressed: onDelete,
                              ),
                            ),
                          ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: t.primary,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox.square(
                              dimension: 40,
                              child: Icon(
                                LucideIcons.arrowUpRight,
                                size: 16,
                                color: t.primaryForeground,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        residence.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.mapPin, size: 14, color: t.muted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              residence.address.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ],
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

/// Nombre de logements en pastille de verre ; une résidence vide passe en
/// sable : elle n'est pas encore louable, et c'est la seule chose à faire
/// ensuite.
class _UnitsPill extends StatelessWidget {
  const _UnitsPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final empty = count == 0;
    final label = empty
        ? 'residence.no_unit'.tr()
        : 'residence.unit_count'.plural(count);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          empty ? LucideIcons.info : LucideIcons.doorOpen,
          size: 14,
          color: empty ? t.onSand : t.foreground,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.text.labelMedium!.copyWith(
            color: empty ? t.onSand : t.foreground,
          ),
        ),
      ],
    );
    const padding = EdgeInsets.symmetric(horizontal: 12, vertical: 7);
    if (empty) {
      return DecoratedBox(
        decoration: BoxDecoration(color: t.sand, borderRadius: AppRadius.pill),
        child: Padding(padding: padding, child: content),
      );
    }
    return FrostedSurface(
      borderRadius: FrostedSurface.pill,
      padding: padding,
      child: content,
    );
  }
}

/// Résidence sans photo : aplat lavande doux et l'icône de la section.
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ColoredBox(
      color: t.accentVioletSoft,
      child: Center(
        child: Icon(
          AppSectionIcons.residences,
          size: 34,
          color: t.accentViolet,
        ),
      ),
    );
  }
}
