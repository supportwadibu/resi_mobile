import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/config/app_config.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/core/utils/country_helper.dart';
import 'package:resi_africa/core/utils/phone_helper.dart';
import 'package:resi_africa/features/auth/business_logic/owner_profile_cubit.dart';
import 'package:resi_africa/features/auth/business_logic/owner_profile_state.dart';
import 'package:resi_africa/features/auth/data/models/owner_profile_model.dart';
import 'package:resi_africa/features/auth/data/services/auth_service.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/skeletons/profile_skeleton.dart';

@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OwnerProfileCubit>()..load(),
      child: const ProfileView(),
    );
  }
}


@visibleForTesting
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // ── AppBar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.maybePop(),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: AppColors.black,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Mon profil',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
          ),

          Expanded(
            child: BlocBuilder<OwnerProfileCubit, OwnerProfileState>(
              builder: (context, state) {
                if (state is OwnerProfileLoading ||
                    state is OwnerProfileInitial) {
                  return const ProfileSkeleton();
                }

                final profile = switch (state) {
                  OwnerProfileReady(:final profile) => profile,
                  OwnerProfileError(:final profile) => profile,
                  OwnerProfileSubmitted(:final profile) => profile,
                  _ => null,
                };

                // Échec de lecture sans dossier en cache : rien de fiable à
                // montrer, mieux vaut proposer une nouvelle tentative que des
                // champs vides qu'on prendrait pour un profil incomplet.
                if (profile == null) {
                  return ErrorState(
                    message: state is OwnerProfileError
                        ? state.message
                        : 'Profil indisponible.',
                    onRetry: () => context.read<OwnerProfileCubit>().load(),
                  );
                }

                return _ProfileContent(profile: profile);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Corps de l'écran, alimenté par le dossier renvoyé par l'API.
class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final OwnerProfileModel profile;

  /// Localisation résumée sous le nom : « Cocody · Abidjan ».
  ///
  /// L'adresse porte la commune en préfixe, faute de champ dédié côté API.
  String? get _locationSummary {
    // Le pays est stocké en code ISO2 : on affiche son libellé, `CI` seul ne
    // parlant pas à l'utilisateur.
    final country =
        CountryHelper.resolve(profile.country)?.name ?? profile.country;

    final parts = [
      profile.city,
      country,
    ].where((p) => p != null && p.trim().isNotEmpty).map((p) => p!.trim());

    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Adresse complète, commune comprise.
  String? get _fullAddress {
    final address = profile.address?.trim();
    final location = _locationSummary;

    if (address == null || address.isEmpty) return location;
    if (location == null) return address;
    return '$address, $location';
  }

  /// Pièce d'identité : « CNI • CI-AB-2019-12345 ».
  String? get _identityDocument {
    final type = profile.idDocumentType?.label;
    final number = profile.idDocumentNumber?.trim();

    if (type == null && (number == null || number.isEmpty)) return null;
    if (number == null || number.isEmpty) return type;
    if (type == null) return number;
    return '$type • $number';
  }

  /// Téléphone remis en forme nationale, plus lisible que l'E.164 stocké.
  String? get _phone {
    final raw = profile.phone?.trim();
    if (raw == null || raw.isEmpty) return null;

    final iso2 = CountryHelper.iso2Of(profile.country);
    if (iso2 == null) return raw;

    final national = PhoneHelper.toNational(raw, iso2);
    return national.isEmpty ? raw : national;
  }

  @override
  Widget build(BuildContext context) {
    // Seules les informations réellement renseignées sont listées : une ligne
    // vide laisserait croire à une donnée manquante côté serveur.
    final items = <_InfoItem>[
      if (profile.fullName.trim().isNotEmpty)
        _InfoItem(
          icon: FontAwesomeIcons.user,
          label: 'Nom complet',
          value: profile.fullName,
        ),
      if (profile.email != null && profile.email!.trim().isNotEmpty)
        _InfoItem(
          icon: FontAwesomeIcons.envelope,
          label: 'Email',
          value: profile.email!,
        ),
      if (_phone != null)
        _InfoItem(
          icon: FontAwesomeIcons.phone,
          label: 'Téléphone',
          value: _phone!,
        ),
      if (_fullAddress != null)
        _InfoItem(
          icon: FontAwesomeIcons.locationDot,
          label: 'Adresse',
          value: _fullAddress!,
        ),
      if (_identityDocument != null)
        _InfoItem(
          icon: FontAwesomeIcons.idCard,
          label: 'Pièce d’identité',
          value: _identityDocument!,
        ),
    ];

    return RefreshIndicator(
      onRefresh: () => context.read<OwnerProfileCubit>().load(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(
              profile: profile,
              locationSummary: _locationSummary,
            ),
            const SizedBox(height: 20),

            _StatusCard(profile: profile),
            const SizedBox(height: 24),

            if (items.isNotEmpty) ...[
              const _SectionTitle(title: 'Informations personnelles'),
              const SizedBox(height: 12),
              _InfoGroup(items: items),
              const SizedBox(height: 24),
            ],

            const _SectionTitle(title: 'Paramètres'),
            const SizedBox(height: 12),
            _SettingsGroup(
              items: [
                _SettingsItem(
                  icon: FontAwesomeIcons.penToSquare,
                  label: 'Modifier mes informations',
                  onTap: () async {
                    await context.router.push(
                      PropertyManagerProfileRoute(),
                    );
                    // Le dossier a pu changer pendant l'édition : on relit
                    // plutôt que d'afficher l'état d'avant.
                    if (context.mounted) {
                      await context.read<OwnerProfileCubit>().load();
                    }
                  },
                ),
                _SettingsItem(
                  icon: FontAwesomeIcons.bell,
                  label: 'Notifications',
                  onTap: () {},
                  trailing: _NotificationToggle(),
                ),
              ],
            ),

            // L'entrée disparaît si aucun identifiant Tawk.to n'est fourni au
            // build : mieux vaut pas de support qu'un écran de chat vide.
            if (AppConfig.isSupportChatEnabled) ...[
              const SizedBox(height: 24),
              const _SectionTitle(title: 'Assistance'),
              const SizedBox(height: 12),
              _SettingsGroup(
                items: [
                  _SettingsItem(
                    icon: FontAwesomeIcons.headset,
                    label: 'Aide & support',
                    onTap: () => _openSupport(context, profile),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            const _SectionTitle(title: 'Compte'),
            const SizedBox(height: 12),
            _SettingsGroup(
              items: [
                _SettingsItem(
                  icon: FontAwesomeIcons.rightFromBracket,
                  label: 'Se déconnecter',
                  onTap: () => _confirmLogout(context),
                  color: AppColors.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Ouvre le chat d'assistance, le visiteur déjà identifié.
  ///
  /// Le support voit ainsi qui écrit sans avoir à le demander, et peut
  /// rattacher la conversation au dossier du propriétaire.
  void _openSupport(BuildContext context, OwnerProfileModel profile) {
    context.router.push(
      SupportChatRoute(
        visitorName: profile.fullName,
        visitorEmail: profile.email,
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment quitter votre session ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // La purge locale prime : même si l'appel serveur échoue, la session ne
    // doit pas survivre à une déconnexion demandée.
    await sl<AuthService>().logout();
    if (!context.mounted) return;

    await context.router.replaceAll([const LoginRoute()]);
  }
}

// ─────────────────────────────────────────
// Header avatar
// ─────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, this.locationSummary});

  final OwnerProfileModel profile;
  final String? locationSummary;

  /// Deux lettres au plus, à défaut de photo.
  String get _initials {
    final words = profile.fullName.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl;
    final subtitle = locationSummary == null
        ? 'Propriétaire'
        : 'Propriétaire · $locationSummary';

    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: avatarUrl == null || avatarUrl.isEmpty
              ? _buildInitials()
              : Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  // L'URL signée expire : son échec ne doit pas laisser un
                  // trou à la place de l'avatar.
                  errorBuilder: (_, _, _) => _buildInitials(),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName.trim().isEmpty
                    ? 'Sans nom'
                    : profile.fullName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitials() => Center(
    child: Text(
      _initials,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    ),
  );
}

// ─────────────────────────────────────────
// État du dossier de validation
// ─────────────────────────────────────────

/// Bandeau d'état du dossier, avec accès à la régularisation si besoin.
///
/// Remplace l'ancienne carte d'abonnement : l'état de validation est ce qui
/// conditionne réellement l'accès aux fonctions du compte.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.profile});

  final OwnerProfileModel profile;

  ({Color color, Color background, FaIconData icon, String message}) get _style {
    if (profile.isValidated) {
      return (
        color: AppColors.success,
        background: AppColors.successBg,
        icon: FontAwesomeIcons.circleCheck,
        message: 'Votre compte est vérifié.',
      );
    }
    if (profile.isRejected) {
      final reason = profile.rejectionReason;
      return (
        color: AppColors.error,
        background: AppColors.errorBg,
        icon: FontAwesomeIcons.circleExclamation,
        message: reason == null || reason.isEmpty
            ? 'Corrigez votre dossier et renvoyez-le.'
            : reason,
      );
    }
    if (profile.isSuspended) {
      return (
        color: AppColors.error,
        background: AppColors.errorBg,
        icon: FontAwesomeIcons.ban,
        message: 'Complétez votre dossier pour retrouver l’accès.',
      );
    }
    if (profile.isSubmitted) {
      return (
        color: AppColors.info,
        background: AppColors.infoBg,
        icon: FontAwesomeIcons.clock,
        message: 'Votre dossier est en cours de vérification.',
      );
    }
    return (
      color: AppColors.warning,
      background: AppColors.warningBg,
      icon: FontAwesomeIcons.circleInfo,
      message: 'Déposez votre pièce d’identité pour valider votre compte.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    // Un dossier validé n'appelle aucune action : le bandeau reste informatif.
    final needsAction = !profile.isValidated;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(style.icon, color: style.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.statusLabel,
                  style: TextStyle(
                    color: style.color,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  style.message,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (needsAction) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () async {
                await context.router.push(PropertyManagerProfileRoute());
                if (context.mounted) {
                  await context.read<OwnerProfileCubit>().load();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: style.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Compléter',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Section title
// ─────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
    );
  }
}

// ─────────────────────────────────────────
// Infos personnelles
// ─────────────────────────────────────────
class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final FaIconData icon;
  final String label;
  final String value;
}

class _InfoGroup extends StatelessWidget {
  const _InfoGroup({required this.items});
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: FaIcon(
                          item.icon,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.grey500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: AppColors.grey200, indent: 64),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Settings
// ─────────────────────────────────────────
class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.trailing,
  });
  final FaIconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          final color = item.color ?? AppColors.black;
          return Column(
            children: [
              GestureDetector(
                onTap: item.onTap,
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: item.color != null
                              ? item.color!.withOpacity(0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: FaIcon(item.icon, size: 14, color: color),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                      item.trailing ??
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: AppColors.grey400,
                          ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: AppColors.grey200, indent: 64),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Toggle notifications
// ─────────────────────────────────────────
class _NotificationToggle extends StatefulWidget {
  @override
  State<_NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<_NotificationToggle> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: _enabled,
      onChanged: (v) => setState(() => _enabled = v),
      activeColor: AppColors.primary,
    );
  }
}
