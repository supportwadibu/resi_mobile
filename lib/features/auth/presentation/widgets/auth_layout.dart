import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/page_header.dart';
import 'package:resi_africa/shared/widgets/app_icon_button.dart';
import 'package:resi_africa/core/theme/app_radius.dart';

/// Gabarit des écrans de connexion, d'inscription et de mot de passe oublié :
/// sur la lueur du fond, trois pastilles inclinées aux accents du système
/// (lavande, sable, neutre) arrivent d'un petit rebond, puis le grand titre
/// et la carte du formulaire montent en fondu. Pas de photo ni de logo :
/// l'écran va droit au formulaire.
class AuthLayout extends StatefulWidget {
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

  /// Bouton retour en haut à gauche, pour l'inscription et le mot de passe
  /// oublié.
  final VoidCallback? onBack;

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout>
    with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // « Réduire les animations » : tout est en place d'emblée.
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else if (_intro.isDismissed) {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// Fondu montant d'un bloc, entre `start` et `end` (fractions de l'intro).
  Widget _rise(double start, double end, Widget child) {
    final a = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(a),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

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
                SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: widget.onBack == null
                        ? null
                        : AppIconButton(
                            icon: LucideIcons.chevronLeft,
                            label: 'common.back'.tr(),
                            bordered: true,
                            onPressed: widget.onBack,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _Stickers(intro: _intro),
                  ),
                ),
                const SizedBox(height: 28),
                _rise(
                  0.25,
                  0.75,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: context.text.displayMedium!.copyWith(
                            fontSize: 34,
                            height: 1.1,
                            letterSpacing: -0.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.description,
                          style: context.mutedText.copyWith(height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _rise(
                  0.4,
                  1,
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Trois pastilles posées de biais qui se chevauchent : une clé sur la
/// lavande, une maison sur le sable, des étincelles sur la surface neutre.
/// Chacune arrive d'un rebond, l'une après l'autre.
class _Stickers extends StatelessWidget {
  const _Stickers({required this.intro});

  final Animation<double> intro;

  static const _size = 64.0;
  static const _step = 46.0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final stickers = [
      (
        icon: LucideIcons.keyRound,
        bg: t.lavender,
        fg: t.onLavender,
        border: t.lavender,
        turn: -0.035,
      ),
      (
        icon: LucideIcons.house,
        bg: t.sand,
        fg: t.onSand,
        border: t.sand,
        turn: 0.025,
      ),
      (
        icon: LucideIcons.sparkles,
        bg: t.surface,
        fg: t.foreground,
        border: t.border,
        turn: -0.012,
      ),
    ];

    return SizedBox(
      width: _size + _step * (stickers.length - 1) + 8,
      height: _size + 12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < stickers.length; i++)
            Positioned(
              left: i * _step,
              top: i.isOdd ? 0 : 10,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: intro,
                  curve: Interval(
                    i * 0.12,
                    0.45 + i * 0.12,
                    curve: Curves.easeOutBack,
                  ),
                ),
                child: RotationTransition(
                  turns: AlwaysStoppedAnimation(stickers[i].turn),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: stickers[i].bg,
                      borderRadius: AppRadius.md,
                      border: Border.all(color: stickers[i].border),
                    ),
                    child: SizedBox.square(
                      dimension: _size,
                      child: Icon(
                        stickers[i].icon,
                        size: 26,
                        color: stickers[i].fg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
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
