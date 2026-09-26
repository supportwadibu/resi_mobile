import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/di/service_locator.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/router/role_guard.dart';
import 'package:resi_africa/core/session/session_role.dart';
import 'package:resi_africa/core/theme/app_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/utils/country_helper.dart';
import 'package:resi_africa/core/utils/phone_helper.dart';
import 'package:resi_africa/features/auth/business_logic/owner_profile_cubit.dart';
import 'package:resi_africa/features/auth/business_logic/owner_profile_state.dart';
import 'package:resi_africa/features/auth/data/models/owner_profile_model.dart';
import 'package:resi_africa/features/auth/data/services/auth_service.dart';
import 'package:resi_africa/features/gerant/data/models/gerant_account_model.dart';
import 'package:resi_africa/features/subscription/business_logic/plan_cubit.dart';
import 'package:resi_africa/features/subscription/presentation/widgets/plan_gate.dart';
import 'package:resi_africa/features/subscription/presentation/widgets/plan_status_card.dart';
import 'package:resi_africa/features/subscription/presentation/widgets/plan_style.dart';
import 'package:resi_africa/features/support/presentation/widgets/support_contact_sheet.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_sheet.dart';
import 'package:resi_africa/shared/widgets/app_top_bar.dart';
import 'package:resi_africa/shared/widgets/confirm_dialog.dart';
import 'package:resi_africa/shared/widgets/error_state.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/skeletons/profile_skeleton.dart';
import 'package:resi_africa/shared/widgets/theme_switcher.dart';

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
      appBar: const AppTopBar(title: 'Mon profil'),
      body: BlocBuilder<OwnerProfileCubit, OwnerProfileState>(
        builder: (context, state) {
          if (state is OwnerProfileLoading || state is OwnerProfileInitial) {
            return const ProfileSkeleton();
          }

          // Branche distincte, et non un `_ProfileContent` aux champs nuls :
          // c'est le type du state qui interdit qu'un dossier de validation
          // ou une pièce d'identité atteigne l'écran du gérant,
          // `GerantAccountModel` n'en portant aucun.
          if (state is ManagerProfileReady) {
            return _ManagerProfileContent(account: state.account);
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
    );
  }
}

/// Corps de l'écran, alimenté par le dossier renvoyé par l'API.
class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final OwnerProfileModel profile;

  /// Rôle de la session, `proprio` par défaut.
  ///
  /// Lu par `isRegistered` plutôt qu'en accès direct : cet écran se monte dans
  /// des tests de widget qui ne câblent pas le conteneur, et y lever ferait
  /// échouer des tests qui ne portent pas sur le rôle. Le repli sur `proprio`
  /// n'ouvre rien : le garde de route refuse le gérant de toute façon.
  String _currentRole() =>
      sl.isRegistered<SessionRole>() ? sl<SessionRole>().value : 'proprio';

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

  Future<void> _editProfile(BuildContext context) async {
    await context.router.push(PropertyManagerProfileRoute());
    // Le dossier a pu changer pendant l'édition : on relit plutôt que
    // d'afficher l'état d'avant.
    if (context.mounted) await context.read<OwnerProfileCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    // Seules les informations réellement renseignées sont listées : une ligne
    // vide laisserait croire à une donnée manquante côté serveur.
    final items = <DetailItem>[
      if (profile.fullName.trim().isNotEmpty)
        DetailItem('Nom complet', profile.fullName, icon: LucideIcons.user),
      if (profile.email != null && profile.email!.trim().isNotEmpty)
        DetailItem('Email', profile.email, icon: LucideIcons.mail),
      if (_phone != null)
        DetailItem('Téléphone', _phone, icon: LucideIcons.phone),
      if (_fullAddress != null)
        DetailItem('Adresse', _fullAddress, icon: LucideIcons.mapPin),
      if (_identityDocument != null)
        DetailItem(
          'Pièce d’identité',
          _identityDocument,
          icon: LucideIcons.idCard,
        ),
    ];

    final settings = <Widget>[
      // L'écran d'édition est le formulaire du dossier propriétaire, que
      // `OwnerRouteGuard` ferme au gérant : l'entrée disparaît pour qu'il ne
      // bute pas sur une redirection muette.
      if (isGestureAllowed(_currentRole(), 'profile_edit'))
        AppSheetAction(
          icon: LucideIcons.squarePen,
          label: 'Modifier mes informations',
          onTap: () => _editProfile(context),
        ),
      // Réservée au propriétaire : le gérant n'ouvre pas de compte gérant, et
      // le garde de route ferme déjà l'écran. L'entrée disparaît pour qu'il ne
      // bute pas sur une redirection.
      if (_currentRole() != 'gerant')
        AppSheetAction(
          icon: AppSectionIcons.managers,
          label: 'Mes gérants',
          trailing: hasFullPlan() ? null : const PremiumBadge(),
          onTap: () {
            if (ensureFullPlan(context, PremiumFeature.managers)) {
              context.router.push(const GerantListRoute());
            }
          },
        ),
    ];

    return RefreshIndicator(
      onRefresh: () => context.read<OwnerProfileCubit>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _Identity(
            name: profile.fullName,
            subtitle: _locationSummary == null
                ? 'Propriétaire'
                : 'Propriétaire · $_locationSummary',
            avatarUrl: profile.avatarUrl,
          ),
          const SizedBox(height: 16),
          _StatusCard(profile: profile, onComplete: () => _editProfile(context)),
          // Le forfait, sous le dossier : les deux conditionnent l'accès. Le
          // gérant n'en a pas — c'est celui de son propriétaire.
          if (_currentRole() != 'gerant') ...[
            const SizedBox(height: 12),
            PlanStatusCard(
              onTap: () => context.router.push(SubscriptionPlansRoute()),
            ),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 24),
            Section(
              title: 'Informations personnelles',
              icon: AppSectionIcons.profile,
              child: DetailList(items: items),
            ),
          ],
          if (settings.isNotEmpty) ...[
            const SizedBox(height: 16),
            _LinkGroup(title: 'Paramètres', children: settings),
          ],
          const SizedBox(height: 16),
          const _AppearanceSection(),
          // L'entrée ne dépend plus de Tawk.to : la feuille propose aussi le
          // téléphone, WhatsApp et le courriel, qui restent joignables même
          // sans widget de chat configuré au build.
          const SizedBox(height: 16),
          _LinkGroup(
            title: 'Assistance',
            children: [
              AppSheetAction(
                icon: AppSectionIcons.support,
                label: 'Aide & support',
                onTap: () => showSupportContactSheet(
                  context,
                  visitorName: profile.fullName,
                  visitorEmail: profile.email,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _LogoutButton(),
        ],
      ),
    );
  }
}

/// Confirme puis ferme la session.
///
/// Hors des deux contenus qui l'appellent, et non recopiée dans chacun : la
/// déconnexion purge la base locale, et un second exemplaire finirait par en
/// oublier une part le jour où la purge s'étoffe.
Future<void> _confirmLogout(BuildContext context) async {
  final confirmed = await showConfirmDialog(
    context: context,
    title: 'Se déconnecter',
    message: 'Voulez-vous vraiment quitter votre session ?',
    confirmLabel: 'Se déconnecter',
    danger: true,
  );

  if (!confirmed || !context.mounted) return;

  // La purge locale prime : même si l'appel serveur échoue, la session ne
  // doit pas survivre à une déconnexion demandée.
  await sl<AuthService>().logout();
  // Le palier appartient à la session : le compte suivant ne doit pas hériter
  // des verrous — ou de l'accès — du précédent.
  await sl<PlanCubit>().clear();
  if (!context.mounted) return;

  await context.router.replaceAll([const LoginRoute()]);
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Se déconnecter',
      icon: LucideIcons.logOut,
      variant: AppButtonVariant.secondary,
      expand: true,
      onPressed: () => _confirmLogout(context),
    );
  }
}

/// Apparence de l'application, commune aux deux rôles.
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    return const Section(
      title: 'Apparence',
      icon: LucideIcons.sunMoon,
      child: ThemeSwitcher(),
    );
  }
}

/// Groupe de liens titré, lignes séparées par un filet.
class _LinkGroup extends StatelessWidget {
  const _LinkGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Section(
      title: title,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Profil du gérant
// ─────────────────────────────────────────

/// Corps de l'écran pour un gérant.
///
/// Écrit à part et non greffé sur `_ProfileContent` : ce que le gérant n'a pas
/// — dossier de validation, pièce d'identité, adresse, ville — n'est pas une
/// donnée manquante mais une notion sans objet pour lui. Les blocs
/// correspondants disparaissent au lieu d'afficher du vide, qui se lirait
/// comme un dossier à compléter alors qu'aucune route ne le lui permettrait.
class _ManagerProfileContent extends StatelessWidget {
  const _ManagerProfileContent({required this.account});

  final GerantAccountModel account;

  /// Le sous-titre annonce le nombre de logements plutôt qu'une ville, que le
  /// compte ne porte pas. Zéro logement s'y écrit en toutes lettres : c'est un
  /// fait servi par `property_ids`, non un relevé manquant — et un gérant sans
  /// périmètre doit comprendre pourquoi ses écrans sont vides.
  String get _subtitle {
    final count = account.propertiesCount;
    if (count == 0) return 'Gérant · aucun logement confié';
    return 'Gérant · $count logement${count > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    // Mêmes règles que chez le propriétaire : seules les informations
    // réellement renseignées sont listées. Le serveur garantit qu'au moins une
    // des deux coordonnées existe, jamais les deux.
    final items = <DetailItem>[
      if (account.fullName.trim().isNotEmpty)
        DetailItem('Nom complet', account.fullName, icon: LucideIcons.user),
      if (account.email != null)
        DetailItem('Email', account.email, icon: LucideIcons.mail),
      if (account.phone != null)
        DetailItem('Téléphone', account.phone, icon: LucideIcons.phone),
    ];

    final active = account.isActive;

    return RefreshIndicator(
      onRefresh: () => context.read<OwnerProfileCubit>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _Identity(name: account.fullName, subtitle: _subtitle),
          const SizedBox(height: 16),
          // État du compte, sans bouton d'action : `is_active` croise l'état
          // du compte et celui de l'affectation — c'est le propriétaire qui
          // les rétablit, d'où l'absence de « Compléter » : lui proposer une
          // action qu'il ne peut pas mener serait pire que l'information seule.
          AppCallout(
            icon: active ? LucideIcons.circleCheck : LucideIcons.circleAlert,
            tone: active ? AppAccent.green : AppAccent.red,
            title: active ? 'Compte actif' : 'Compte suspendu',
            message: active
                ? 'Vous gérez les logements qui vous sont confiés.'
                : 'Contactez le propriétaire pour retrouver l’accès.',
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 24),
            // « Mes informations » plutôt que « Informations personnelles » :
            // `PATCH /gerant/profile` n'accepte ni l'e-mail ni le téléphone,
            // et rien à l'écran ne doit laisser croire au gérant qu'il peut
            // les corriger.
            Section(
              title: 'Mes informations',
              icon: AppSectionIcons.profile,
              child: DetailList(items: items),
            ),
          ],
          const SizedBox(height: 16),
          const _AppearanceSection(),
          const SizedBox(height: 16),
          _LinkGroup(
            title: 'Assistance',
            children: [
              AppSheetAction(
                icon: AppSectionIcons.support,
                label: 'Aide & support',
                onTap: () => showSupportContactSheet(
                  context,
                  visitorName: account.fullName,
                  visitorEmail: account.email,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _LogoutButton(),
        ],
      ),
    );
  }
}

/// Identité en tête de profil : avatar carré (photo ou initiales), nom et
/// sous-titre.
class _Identity extends StatelessWidget {
  const _Identity({required this.name, required this.subtitle, this.avatarUrl});

  final String name;
  final String subtitle;
  final String? avatarUrl;

  /// Deux lettres au plus, à défaut de photo.
  String get _initials {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final url = avatarUrl;
    final initials = Center(
      child: Text(_initials, style: context.text.titleLarge),
    );

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: t.background,
            border: Border.all(color: t.border),
          ),
          child: url == null || url.isEmpty
              ? initials
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  // L'URL signée expire : son échec ne doit pas laisser un
                  // trou à la place de l'avatar.
                  errorBuilder: (_, _, _) => initials,
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.trim().isEmpty ? 'Sans nom' : name,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: context.mutedText,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// État du dossier de validation
// ─────────────────────────────────────────

/// Encart d'état du dossier, avec accès à la régularisation si besoin.
///
/// Remplace l'ancienne carte d'abonnement : l'état de validation est ce qui
/// conditionne réellement l'accès aux fonctions du compte. Le ton suit la
/// grammaire des statuts : vert en règle, bleu pris en compte, ambre en
/// attente d'action, rouge arrêté.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.profile, required this.onComplete});

  final OwnerProfileModel profile;
  final VoidCallback onComplete;

  ({AppAccent tone, IconData icon, String message}) get _style {
    if (profile.isValidated) {
      return (
        tone: AppAccent.green,
        icon: LucideIcons.circleCheck,
        message: 'Votre compte est vérifié.',
      );
    }
    if (profile.isRejected) {
      final reason = profile.rejectionReason;
      return (
        tone: AppAccent.red,
        icon: LucideIcons.circleAlert,
        message: reason == null || reason.isEmpty
            ? 'Corrigez votre dossier et renvoyez-le.'
            : reason,
      );
    }
    if (profile.isSuspended) {
      return (
        tone: AppAccent.red,
        icon: LucideIcons.ban,
        message: 'Complétez votre dossier pour retrouver l’accès.',
      );
    }
    if (profile.isSubmitted) {
      return (
        tone: AppAccent.blue,
        icon: LucideIcons.clock,
        message: 'Votre dossier est en cours de vérification.',
      );
    }
    return (
      tone: AppAccent.amber,
      icon: LucideIcons.info,
      message: 'Déposez votre pièce d’identité pour valider votre compte.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    // Un dossier validé n'appelle aucune action : l'encart reste informatif.
    final needsAction = !profile.isValidated;

    return AppCallout(
      icon: style.icon,
      tone: style.tone,
      title: profile.statusLabel,
      message: style.message,
      action: needsAction
          ? AppButton(
              label: 'Compléter mon dossier',
              size: AppButtonSize.sm,
              trailingIcon: LucideIcons.arrowRight,
              onPressed: onComplete,
            )
          : null,
    );
  }
}
