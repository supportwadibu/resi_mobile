import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_logo.dart';

/// Gabarit des écrans de connexion et d'inscription, transposé de la page de
/// connexion du backoffice : la photo et son accroche en haut, sur un voile
/// `overlay` identique dans les deux modes ; le formulaire en dessous, sur le
/// fond de page, qui suit le thème.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    required this.title,
    required this.description,
    required this.child,
    this.onBack,
    super.key,
  });

  final String title;
  final String description;
  final Widget child;

  /// Bouton retour posé sur la photo, pour l'inscription.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final heroHeight = MediaQuery.sizeOf(context).height * 0.3;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: heroHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/splash.png', fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          t.overlay.withValues(alpha: 0.6),
                          t.overlay.withValues(alpha: 0.35),
                          t.overlay.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (onBack != null) ...[
                                Tooltip(
                                  message: 'Retour',
                                  child: InkWell(
                                    onTap: onBack,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Icon(
                                        LucideIcons.chevronLeft,
                                        color: t.onOverlay,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              const AppLogo(height: 28, onMedia: true),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            'Toute votre gestion locative, depuis votre '
                            'téléphone.',
                            style: context.text.titleLarge!.copyWith(
                              color: t.onOverlay,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Réservations, clients, dépenses et revenus.',
                            style: context.text.bodyMedium!.copyWith(
                              color: t.onOverlay.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  24,
                  16,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: context.text.headlineSmall),
                    const SizedBox(height: 4),
                    Text(description, style: context.mutedText),
                    const SizedBox(height: 24),
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton « Continuer avec Google » : variante secondaire, logo de marque
/// avant le libellé.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: SvgPicture.asset(
          'assets/icons/google_logo.svg',
          width: 18,
          height: 18,
        ),
        label: Text(label),
      ),
    );
  }
}

/// Séparateur « ou » entre deux modes de connexion.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou', style: context.text.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
