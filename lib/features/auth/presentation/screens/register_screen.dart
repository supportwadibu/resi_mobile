import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_loader.dart';
import 'package:resi_africa/shared/widgets/app_toast.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import '../../../../core/di/service_locator.dart';
import '../../business_logic/auth_cubit.dart';
import '../../business_logic/auth_state.dart';
import '../widgets/auth_layout.dart';

@RoutePage()
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  static const _highlights = [
    'auth.highlight_trial',
    'auth.highlight_offline',
    'auth.highlight_tracking',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // Un compte fraîchement créé doit d'abord déposer son dossier
            // d'identité : sans lui, il sera suspendu à la fin de l'essai.
            // L'écran d'essai vient ensuite, et annonce sa durée. Une
            // simple reconnexion va droit à l'accueil.
            context.router.replaceAll([
              if (state.auth.isNewUser)
                PropertyManagerProfileRoute(isOnboarding: true)
              else
                const HomeRoute(),
            ]);
          }
          if (state is AuthOtpSent) {
            // Le compte est créé mais pas encore vérifié : la session ne
            // s'ouvre qu'après la saisie du code.
            AppToast.info(
              'auth.code_sent'.tr(args: [state.target]),
              context: context,
            );
          }
          if (state is AuthError) {
            AppToast.error(state.message, context: context);
          }
        },
        builder: (context, state) {
          final t = context.tokens;
          return AuthLayout(
            title: 'auth.register_title'.tr(),
            description: 'auth.register_description'.tr(),
            onBack: () => context.router.maybePop(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final line in _highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(LucideIcons.check, size: 16, color: t.accentGreen),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(line.tr(), style: context.text.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                if (state is AuthLoading)
                  const Center(child: AppLoader())
                else
                  GoogleSignInButton(
                    label: 'auth.sign_up_google'.tr(),
                    // Même appel que sur l'écran de connexion : côté API,
                    // `/auth/google` crée le compte s'il n'existe pas et
                    // connecte sinon. Le drapeau `is_new_user` de la réponse
                    // distingue les deux cas pour l'onboarding.
                    onPressed: () =>
                        context.read<AuthCubit>().loginWithGoogle(),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('auth.has_account'.tr(), style: context.mutedText),
                    TextButton(
                      onPressed: () => context.router.maybePop(),
                      child: Text('auth.sign_in'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
