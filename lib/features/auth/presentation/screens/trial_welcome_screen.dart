import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';
import 'package:resi_africa/shared/widgets/app_callout.dart';
import 'package:resi_africa/shared/widgets/app_logo.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/models/subscription_status_model.dart';
import '../../data/services/auth_service.dart';

@RoutePage()
class TrialWelcomeScreen extends StatefulWidget {
  const TrialWelcomeScreen({super.key});

  @override
  State<TrialWelcomeScreen> createState() => _TrialWelcomeScreenState();
}

class _TrialWelcomeScreenState extends State<TrialWelcomeScreen> {
  late Future<SubscriptionStatusModel> _status;

  @override
  void initState() {
    super.initState();
    _status = sl<AuthService>().subscriptionStatus();
  }

  void _goToHome() {
    context.router.replaceAll([const HomeRoute()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<SubscriptionStatusModel>(
          future: _status,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final status = snapshot.data;
            final days = _trialDays(status);
            final showDocLink = status != null && !status.profileSubmitted;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: AppLogo(height: 28),
                      ),
                      const SizedBox(height: 40),
                      // Le cadeau de l'essai prend le violet du forfait
                      // d'essai, « en cours » dans la grammaire des statuts.
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: IconChip(
                          icon: LucideIcons.gift,
                          accent: AppAccent.violet,
                          size: 56,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Bienvenue sur RESI',
                        style: context.text.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      _RichSubtitle(days: days, loading: loading),
                      const SizedBox(height: 24),
                      if (!loading)
                        AppCallout(
                          icon: LucideIcons.calendarClock,
                          tone: days > 0 ? AppAccent.violet : AppAccent.neutral,
                          title: days > 0
                              ? 'Essai de $days jour${days > 1 ? 's' : ''}'
                              : 'Sans engagement',
                          message: _terms(days),
                        ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: days > 0
                            ? 'Démarrer mon essai gratuit'
                            : 'Commencer',
                        trailingIcon: LucideIcons.arrowRight,
                        onPressed: loading ? null : _goToHome,
                        expand: true,
                      ),
                      if (showDocLink) ...[
                        const SizedBox(height: 8),
                        AppButton(
                          label: 'Transmettre ma pièce d’identité',
                          icon: LucideIcons.idCard,
                          variant: AppButtonVariant.ghost,
                          onPressed: _goToDocuments,
                          expand: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // TODO: remplacer par la vraie route du dépôt de documents.
  void _goToDocuments() {
    // context.router.push(const IdentityDocumentsRoute());
  }

  int _trialDays(SubscriptionStatusModel? status) {
    if (status == null || !status.isTrial) return 0;
    return status.daysRemaining > 0 ? status.daysRemaining : 0;
  }

  String _terms(int days) {
    if (days == 0) {
      return 'Aucun engagement. Résiliable à tout moment.';
    }
    final plural = days > 1 ? 's' : '';
    return 'Essai de $days jour$plural offert$plural,\n'
        'puis forfait Pro ou Premium.';
  }
}

/// Sous-titre avec amorce en gras, comme sur la maquette.
class _RichSubtitle extends StatelessWidget {
  const _RichSubtitle({required this.days, required this.loading});

  final int days;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(context, 240),
          const SizedBox(height: 10),
          _bar(context, 180),
        ],
      );
    }

    return Text.rich(
      TextSpan(
        style: context.mutedText.copyWith(height: 1.55),
        children: [
          TextSpan(
            text: 'Votre compte est prêt. ',
            style: context.text.titleSmall!.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: days > 0
                ? 'Gérez vos biens et vos locataires sans limite pendant '
                      'toute la durée de l’essai.'
                : 'Gérez vos biens et vos locataires depuis un seul endroit.',
          ),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, double width) =>
      Container(width: width, height: 12, color: context.tokens.border);
}
