import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_badge.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

import '../../../../data/models/owner_profile_model.dart';

/// Carte d'identité du gestionnaire, en tête de l'écran de profil.
///
/// N'affiche que ce que l'API renvoie réellement : avatar, nom, e-mail et
/// statut du dossier. Les champs absents sont omis plutôt que remplacés par
/// des valeurs d'attente, qui donneraient à croire à des données existantes.
class OwnerProfileHeader extends StatelessWidget {
  const OwnerProfileHeader({super.key, required this.profile});

  final OwnerProfileModel profile;

  @override
  Widget build(BuildContext context) {
    final email = profile.email;

    return AppCard(
      child: Row(
        children: [
          _Avatar(url: profile.avatarUrl, fullName: profile.fullName),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.fullName.isEmpty
                      ? 'owner_profile.no_name'.tr()
                      : profile.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium,
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: context.mutedText,
                  ),
                ],
                const SizedBox(height: 8),
                OwnerStatusBadge(profile: profile),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo du gestionnaire, ou ses initiales à défaut.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.fullName});

  final String? url;
  final String fullName;

  /// Deux lettres au plus : première du prénom et du dernier mot du nom.
  String get _initials {
    final words = fullName.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final imageUrl = url;
    final initials = Center(
      child: Text(_initials, style: context.text.titleLarge),
    );

    return Container(
      width: 56,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.background,
        borderRadius: AppRadius.pill,
        border: Border.all(color: t.border),
      ),
      child: imageUrl == null || imageUrl.isEmpty
          ? initials
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              // L'URL est signée et temporaire : son expiration ne doit pas
              // laisser un trou à la place de l'avatar.
              errorBuilder: (_, _, _) => initials,
            ),
    );
  }
}

/// Pastille d'état du dossier de validation, selon la grammaire des statuts :
/// vert validé, bleu en vérification, ambre à déposer, rouge refusé ou
/// suspendu.
class OwnerStatusBadge extends StatelessWidget {
  const OwnerStatusBadge({super.key, required this.profile});

  final OwnerProfileModel profile;

  ({AppAccent tone, IconData icon}) get _style {
    if (profile.isValidated) {
      return (tone: AppAccent.green, icon: LucideIcons.circleCheck);
    }
    if (profile.isRejected) {
      return (tone: AppAccent.red, icon: LucideIcons.circleAlert);
    }
    if (profile.isSuspended) {
      return (tone: AppAccent.red, icon: LucideIcons.ban);
    }
    if (profile.isSubmitted) {
      return (tone: AppAccent.blue, icon: LucideIcons.clock);
    }
    return (tone: AppAccent.amber, icon: LucideIcons.info);
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    return AppBadge(
      label: profile.statusLabel,
      tone: style.tone,
      icon: style.icon,
    );
  }
}
