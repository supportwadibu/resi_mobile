import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_badge.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

import '../../business_logic/plan_state.dart';
import '../../data/models/plan_access.dart';

/// Identité visuelle d'un forfait : nom, icône, ton.
///
/// Source unique : la carte « Mon forfait », l'écran des forfaits, le badge et
/// la feuille de verrou lisent tous ici, si bien qu'un forfait garde la même
/// allure partout. Les tons suivent la grammaire des statuts du backoffice
/// (`PLAN_TIER_TONES`) : l'essai est en cours (violet), le palier gratuit hors
/// circuit payant (neutre), Pro actif mais réduit (bleu), Pro+ complet et en
/// règle (vert).
enum PlanStyle {
  trial(
    LucideIcons.gift,
    AppAccent.violet,
    'plans.trial_name',
    'plans.trial_tagline',
  ),
  free(
    LucideIcons.house,
    AppAccent.neutral,
    'plans.free_name',
    'plans.free_tagline',
  ),
  pro(
    LucideIcons.layers,
    AppAccent.blue,
    'plans.pro_name',
    'plans.pro_tagline',
  ),
  proPlus(
    LucideIcons.crown,
    AppAccent.green,
    'plans.pro_plus_name',
    'plans.pro_plus_tagline',
  );

  /// Allure du palier [access] ; `null` pour un compte inactif.
  static PlanStyle? of(PlanAccess access) => switch (access) {
    PlanAccess.proPlus => PlanStyle.proPlus,
    PlanAccess.pro => PlanStyle.pro,
    PlanAccess.free => PlanStyle.free,
    PlanAccess.inactive => null,
  };

  const PlanStyle(this.icon, this.accent, this._nameKey, this._taglineKey);

  final IconData icon;
  final AppAccent accent;
  final String _nameKey;
  final String _taglineKey;

  String get label => _nameKey.tr();
  String get tagline => _taglineKey.tr();

  /// Ton plein du forfait dans le mode courant.
  Color colorOf(BuildContext context) => context.tokens.accent(accent);

  /// Fond doux du forfait, pour les pastilles et les cartes.
  Color softOf(BuildContext context) => context.tokens.accentSoft(accent);
}

/// Forfait en cours, tel que l'état du palier le décrit ; `null` pour un
/// compte inactif.
///
/// Un essai ouvre l'accès complet, mais s'affiche comme essai : c'est le forfait
/// que le propriétaire a, pas celui qu'il a payé.
PlanStyle? currentPlanStyle(PlanState state) {
  if (state is PlanKnown && state.isTrial) return PlanStyle.trial;
  return PlanStyle.of(state.access);
}

/// Fonctions réservées à un palier payant, et le palier minimal qui les ouvre.
///
/// Chaque verrou nomme la fonction demandée et l'offre qui l'ouvre :
/// « Rapports PDF, c'est avec RESI Pro+ » dit ce qu'on obtient, là où un
/// « Accès refusé » générique ne dit rien. Les paliers suivent les groupes de
/// routes de l'API (`start/routes.ts`).
enum PremiumFeature {
  statistics(LucideIcons.chartLine, PlanAccess.pro),
  finance(LucideIcons.scale, PlanAccess.pro),
  clients(LucideIcons.users, PlanAccess.pro),
  expenses(LucideIcons.banknote, PlanAccess.pro),
  reports(LucideIcons.fileText, PlanAccess.proPlus),
  managers(LucideIcons.userCog, PlanAccess.proPlus),
  invoices(LucideIcons.receiptText, PlanAccess.proPlus);

  const PremiumFeature(this.icon, this.requiredAccess);

  final IconData icon;

  /// Palier minimal qui ouvre la fonction.
  final PlanAccess requiredAccess;

  /// Allure de l'offre qui ouvre la fonction.
  PlanStyle get plan => PlanStyle.of(requiredAccess)!;

  String get title => 'premium.features.$name.title'.tr();
  String get body => 'premium.features.$name.body'.tr();
}

/// Pastille d'icône d'un forfait, au ton du forfait.
class PlanIconBadge extends StatelessWidget {
  const PlanIconBadge({required this.style, this.size = 44, super.key});

  final PlanStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconChip(icon: style.icon, accent: style.accent, size: size);
  }
}

/// Petite étiquette de l'offre — « Pro », « Pro+ » —, posée sur une entrée
/// verrouillée.
///
/// Remplace le cadenas : elle dit ce qui ouvre l'entrée, pas seulement
/// qu'elle est fermée.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({required this.feature, super.key});

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    final plan = feature.plan;
    return AppBadge(
      label: 'premium.badge_${plan.name}'.tr(),
      icon: plan.icon,
      tone: plan.accent,
    );
  }
}
