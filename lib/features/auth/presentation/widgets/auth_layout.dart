import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/app_logo.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/frosted_surface.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/core/theme/app_radius.dart';

/// Gabarit des écrans de connexion et d'inscription, d'après les maquettes :
/// la photo encadrée en carte arrondie, logo et retour en verre dessus,
/// l'accroche en bas de la photo ; puis le grand titre et le formulaire dans
/// une carte. La lueur prune du mode sombre couvre tout l'écran.
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
    final heroHeight = MediaQuery.sizeOf(context).height * 0.28;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: t.glowGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.lg,
                  child: SizedBox(
                    height: heroHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/splash.png',
                          fit: BoxFit.cover,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                t.overlay.withValues(alpha: 0.25),
                                t.overlay.withValues(alpha: 0.05),
                                t.overlay.withValues(alpha: 0.75),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (onBack != null) ...[
                                    FrostedSurface(
                                      borderRadius: FrostedSurface.pill,
                                      child: AppIconButton(
                                        icon: LucideIcons.chevronLeft,
                                        label: 'common.back'.tr(),
                                        onPressed: onBack,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  FrostedSurface(
                                    borderRadius: FrostedSurface.pill,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    child: const AppLogo(height: 22),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                'auth.tagline'.tr(),
                                style: context.text.titleLarge!.copyWith(
                                  color: t.onOverlay,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'auth.tagline_sub'.tr(),
                                style: context.text.bodySmall!.copyWith(
                                  color: t.onOverlay.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.displayMedium!.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(description, style: context.mutedText),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                AppCard(padding: const EdgeInsets.all(18), child: child),
              ],
            ),
          ),
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
      height: 52,
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
          child: Text('auth.or'.tr(), style: context.text.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
