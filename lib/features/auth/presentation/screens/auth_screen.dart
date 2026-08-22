import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/features/auth/data/services/auth_service.dart';
import 'package:resi_africa/features/auth/data/services/property_manager_service.dart';
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
        await context.router.replaceAll([const LoginRoute()]);
        return;
      }

      final submitted = await sl<PropertyManagerService>().isProfileSubmitted();
      if (!mounted) return;

      await context.router.replaceAll([
        if (submitted == false)
          PropertyManagerProfileRoute(isOnboarding: true)
        else
          const HomeRoute(),
      ]);
    } catch (_) {
      if (!mounted) return;
      await context.router.replaceAll([const LoginRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AppLoaderScreen();
  }
}
