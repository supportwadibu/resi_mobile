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
/// (`PLAN_TIER_TONES`) : l'essai est en cours (violet), le forfait
/// d'enregistrement actif mais réduit (bleu), le forfait complet en règle
/// (vert).
enum PlanStyle {
  trial(
    LucideIcons.gift,
    AppAccent.violet,
    'plans.trial_name',
    'plans.trial_tagline',
  ),
  basic(
    LucideIcons.layers,
    AppAccent.blue,
    'plans.basic_name',
    'plans.basic_tagline',
  ),
  full(
    LucideIcons.crown,
    AppAccent.green,
    'plans.full_name',
    'plans.full_tagline',
  );

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
  return switch (state.access) {
    PlanAccess.full => PlanStyle.full,
    PlanAccess.basic => PlanStyle.basic,
    PlanAccess.inactive => null,
  };
}

/// Fonctions réservées au forfait Premium.
///
/// Chaque verrou nomme la fonction demandée : « Rapports PDF, c'est avec
/// Premium » dit ce qu'on obtient, là où un « Accès refusé » générique ne dit
/// rien.
enum PremiumFeature {
  statistics(LucideIcons.chartLine),
  finance(LucideIcons.scale),
  reports(LucideIcons.fileText),
  clients(LucideIcons.users),
  expenses(LucideIcons.banknote),
  managers(LucideIcons.userCog),
  invoices(LucideIcons.receiptText);

  const PremiumFeature(this.icon);

  final IconData icon;

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

/// Petite étiquette « Premium », posée sur une entrée verrouillée.
///
/// Remplace le cadenas : elle dit ce qui ouvre l'entrée, pas seulement
/// qu'elle est fermée.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: 'premium.badge'.tr(),
      icon: PlanStyle.full.icon,
      tone: PlanStyle.full.accent,
    );
  }
}
