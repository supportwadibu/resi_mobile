import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_colors.dart';
import 'package:resi_africa/shared/widgets/app_button.dart';

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
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: FutureBuilder<SubscriptionStatusModel>(
          future: _status,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final status = snapshot.data;
            final days = _trialDays(status);
            final showDocLink = status != null && !status.profileSubmitted;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const Expanded(flex: 5, child: _TrialIllustration()),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _AccentTitle(),
                            const SizedBox(height: 16),
                            _RichSubtitle(days: days, loading: loading),
                            const SizedBox(height: 28),
                            if (!loading)
                              Text(
                                _terms(days),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: AppColors.grey600,
                                ),
                              ),
                            const SizedBox(height: 32),
                            AppButton(
                              label: days > 0
                                  ? 'Démarrer mon essai gratuit'
                                  : 'Commencer',
                              onPressed: loading ? null : _goToHome,
                              width: double.infinity,
                              fontSize: 16,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            const SizedBox(height: 18),
                            if (showDocLink)
                              TextButton(
                                onPressed: _goToDocuments,
                                child: const Text(
                                  'Transmettre ma pièce d’identité',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.warning,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
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
    // TODO: brancher le tarif réel depuis SubscriptionStatusModel.
    return 'Essai de $days jour$plural offert$plural,\n'
        'puis abonnement mensuel.';
  }
}

/// Bloc illustration. Remplace le contenu par un Image.asset dès que le
/// visuel définitif est prêt : la structure autour ne bouge pas.
class _TrialIllustration extends StatelessWidget {
  const _TrialIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.warning.withValues(alpha: 0.06),
          ),
        ),
        Container(
          width: 150,
          height: 150,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: const FaIcon(
            FontAwesomeIcons.gift,
            size: 58,
            color: AppColors.white,
          ),
        ),
        const Positioned(top: 30, left: 46, child: _Dot(size: 10)),
        const Positioned(top: 74, right: 40, child: _Dot(size: 7)),
        const Positioned(bottom: 52, left: 62, child: _Dot(size: 6)),
        const Positioned(bottom: 34, right: 58, child: _Dot(size: 11)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.warning.withValues(alpha: 0.35),
      ),
    );
  }
}

/// Titre à deux tons : le nom de marque prend le dégradé.
class _AccentTitle extends StatelessWidget {
  const _AccentTitle();

  static const _style = TextStyle(
    fontSize: 27,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Bienvenue sur ', style: _style),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: const Text(
            'Resi',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.2,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
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
        children: [_bar(240), const SizedBox(height: 10), _bar(180)],
      );
    }

    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: AppColors.grey600,
        ),
        children: [
          const TextSpan(
            text: 'Votre compte est prêt. ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          TextSpan(
            text: days > 0
                ? 'Gérez vos biens et vos locataires sans limite pendant '
                      'toute la durée de l’essai.'
                : 'Gérez vos biens et vos locataires depuis un seul endroit.',
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _bar(double width) => Container(
    width: width,
    height: 12,
    decoration: BoxDecoration(
      color: AppColors.grey600.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}
