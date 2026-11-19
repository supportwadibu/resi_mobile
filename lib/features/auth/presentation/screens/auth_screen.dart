import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/features/auth/data/services/auth_service.dart';
import 'package:resi_africa/features/subscription/business_logic/trial_choice.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import '../../../../core/di/service_locator.dart';

@RoutePage()
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    try {
      final loggedIn = await sl<AuthService>().isLoggedIn();
      if (!mounted) return;

      if (!loggedIn) {
        await context.router.replaceAll([const WelcomeRoute()]);
        return;
      }

      // Le dossier d'identité n'est imposé qu'à l'inscription : « Plus tard »
      // y a été proposé, et le bandeau de l'accueil invite à le compléter.
      // Le rouvrir à chaque lancement annulerait ce choix. Seul le forfait
      // de l'essai, s'il n'est pas encore choisi, passe avant l'accueil.
      final mustChoose = await mustChooseTrialPlan(whenUnknown: false);
      if (!mounted) return;

      await context.router.replaceAll([
        if (mustChoose) const TrialPlanChoiceRoute() else const HomeRoute(),
      ]);
    } catch (_) {
      if (!mounted) return;
      await context.router.replaceAll([const WelcomeRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AppLoaderScreen();
  }
}
