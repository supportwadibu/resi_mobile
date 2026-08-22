import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import '../../../../core/di/service_locator.dart';
import '../../business_logic/auth_cubit.dart';
import '../../business_logic/auth_state.dart';

@RoutePage()
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // Un compte fraîchement créé doit d'abord déposer son dossier
            // d'identité : sans lui, il sera suspendu à la fin de l'essai.
            // L'écran d'essai vient ensuite, et annonce les 14 jours. Une
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Code envoyé à ${state.target}')),
            );
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: Stack(
              children: [
                // ── Fond image plein écran
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/splash.png',
                    fit: BoxFit.cover,
                  ),
                ),

                // ── Dégradé noir transparent
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.95),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── Contenu
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bouton retour
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => context.router.pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Text(
                            '🏢 Nouveau compte',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Titre
                        const Text(
                          'Rejoignez RESI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Sous-titre
                        Text(
                          'Créez votre compte et commencez\nà gérer vos biens immobiliers.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Bouton Google
                        if (state is AuthLoading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Même appel que sur l'écran de connexion :
                                // côté API, `/auth/google` crée le compte s'il
                                // n'existe pas et connecte sinon. Le drapeau
                                // `is_new_user` de la réponse distingue les
                                // deux cas pour l'onboarding.
                                context.read<AuthCubit>().loginWithGoogle();
                              },
                              icon: SvgPicture.asset(
                                'assets/icons/google_logo.svg',
                                width: 22,
                                height: 22,
                              ),
                              label: const Text(
                                "S'inscrire avec Google",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Lien login
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Déjà un compte ? ",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.router.pop(),
                                child: const Text(
                                  "Se connecter",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
