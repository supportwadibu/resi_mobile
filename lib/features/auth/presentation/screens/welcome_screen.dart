import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_radius.dart';
import 'package:resi_africa/core/theme/app_theme.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';
import 'package:resi_africa/shared/widgets/frosted_surface.dart';

/// Écran de bienvenue, avant la connexion : le ruban irisé tourne lentement
/// sur le fond prune. Toujours en sombre — c'est la maquette, et le ruban
/// n'a pas de version claire.
@RoutePage()
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // « Réduire les animations » fige le ruban, sans le retirer.
    if (MediaQuery.disableAnimationsOf(context)) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark(),
      child: Builder(
        builder: (context) {
          final t = context.tokens;
          return Scaffold(
            backgroundColor: t.background,
            body: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.4, -0.65),
                      radius: 1.2,
                      colors: [t.glow, t.background],
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _spin,
                  builder: (context, _) => CustomPaint(
                    painter: _RibbonPainter(
                      turn: _spin.value,
                      colors: t.ribbon,
                    ),
                  ),
                ),
                // Voile du bas : le texte se lit quelle que soit la position
                // du ruban.
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: 0.5,
                    widthFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            t.background.withValues(alpha: 0),
                            t.background.withValues(alpha: 0.85),
                            t.background,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            FrostedSurface(
                              borderRadius: AppRadius.sm,
                              child: SizedBox.square(
                                dimension: 34,
                                child: Center(
                                  child: Text(
                                    'R',
                                    style: context.text.titleSmall!.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'RESI',
                              style: context.text.titleSmall!.copyWith(
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'welcome.title'.tr(),
                          style: context.text.displayLarge!.copyWith(
                            fontSize: 40,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('welcome.subtitle'.tr(), style: context.mutedText),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 6,
                              decoration: BoxDecoration(
                                color: t.foreground,
                                borderRadius: AppRadius.pill,
                              ),
                            ),
                            const Spacer(),
                            _StartButton(
                              onTap: () => context.router.replaceAll([
                                const LoginRoute(),
                              ]),
                            ),
                          ],
                        ),
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

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.foreground,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'welcome.start'.tr(),
                style: context.text.titleSmall!.copyWith(color: t.background),
              ),
              const SizedBox(width: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: t.background,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 44,
                  child: Icon(
                    LucideIcons.arrowRight,
                    size: 18,
                    color: t.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trois anneaux épais à dégradé circulaire, posés comme sur la maquette
/// (repère de 390 pt de large) et tournant chacun à son rythme : la couleur
/// semble couler le long d'un ruban.
class _RibbonPainter extends CustomPainter {
  _RibbonPainter({required this.turn, required this.colors});

  final double turn;
  final List<Color> colors;

  static const _rings = [
    (x: 310.0, y: 90.0, r: 180.0, speed: 1.0, from: 0.0),
    (x: 15.0, y: 335.0, r: 165.0, speed: -0.78, from: 0.35),
    (x: 310.0, y: 440.0, r: 140.0, speed: 0.64, from: 0.6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 390;
    const thickness = 78.0;
    for (final ring in _rings) {
      final center = Offset(ring.x * k, ring.y * k);
      final radius = (ring.r - thickness / 2) * k;
      final angle = (turn * ring.speed + ring.from) * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness * k
        ..shader = SweepGradient(
          colors: [...colors, colors.first],
          transform: GradientRotation(angle),
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.turn != turn;
}
