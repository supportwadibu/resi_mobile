import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/theme/app_colors.dart';

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
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
                  profile.fullName.isEmpty ? 'Sans nom' : profile.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
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
    final imageUrl = url;

    return Container(
      width: 58,
      height: 58,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: imageUrl == null || imageUrl.isEmpty
          ? _buildInitials()
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              // L'URL est signée et temporaire : son expiration ne doit pas
              // laisser un trou à la place de l'avatar.
              errorBuilder: (_, _, _) => _buildInitials(),
            ),
    );
  }

  Widget _buildInitials() => Center(
    child: Text(
      _initials,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.white,
      ),
    ),
  );
}

/// Pastille d'état du dossier de validation.
class OwnerStatusBadge extends StatelessWidget {
  const OwnerStatusBadge({super.key, required this.profile});

  final OwnerProfileModel profile;

  ({Color color, Color background, FaIconData icon}) get _style {
    if (profile.isValidated) {
      return (
        color: AppColors.success,
        background: AppColors.successBg,
        icon: FontAwesomeIcons.circleCheck,
      );
    }
    if (profile.isRejected) {
      return (
        color: AppColors.error,
        background: AppColors.errorBg,
        icon: FontAwesomeIcons.circleExclamation,
      );
    }
    if (profile.isSuspended) {
      return (
        color: AppColors.error,
        background: AppColors.errorBg,
        icon: FontAwesomeIcons.ban,
      );
    }
    if (profile.isSubmitted) {
      return (
        color: AppColors.info,
        background: AppColors.infoBg,
        icon: FontAwesomeIcons.clock,
      );
    }
    return (
      color: AppColors.warning,
      background: AppColors.warningBg,
      icon: FontAwesomeIcons.circleInfo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(style.icon, size: 11, color: style.color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              profile.statusLabel,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: style.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
