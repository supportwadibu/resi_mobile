import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import '../../../../core/di/service_locator.dart';
import '../../business_logic/auth_cubit.dart';
import '../../business_logic/auth_state.dart';

@RoutePage()
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // `/auth/google` inscrit autant qu'il connecte : un nouveau compte
            // peut naître depuis cet écran, et doit alors passer par la
            // finalisation du dossier avant d'atteindre l'accueil.
            context.router.replaceAll([
              if (state.auth.isNewUser)
                PropertyManagerProfileRoute(isOnboarding: true)
              else
                const HomeRoute(),
            ]);
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          // AuthCancelled : l'utilisateur a fermé la feuille Google.
          // Le builder rétablit le bouton, aucun message n'est nécessaire.
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
                            '🏢 Gestion de résidence',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Titre
                        const Text(
                          'Bienvenue sur RESI',
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
                          'Gérez vos résidences, locataires et paiements \nen toute simplicité.',
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
                                context.read<AuthCubit>().loginWithGoogle();
                              },
                              icon: SvgPicture.asset(
                                'assets/icons/google_logo.svg',
                                width: 22,
                                height: 22,
                              ),
                              label: const Text(
                                'Se connecter avec Google',
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

                        // Lien inscription
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Pas encore de compte ? ",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    context.router.push(const RegisterRoute()),
                                child: const Text(
                                  "S'inscrire",
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
