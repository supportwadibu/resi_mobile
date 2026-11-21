import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:resi_africa/core/router/app_router.gr.dart';
import 'package:resi_africa/core/theme/app_theme.dart';
import 'package:resi_africa/core/theme/app_typography.dart';
import 'package:resi_africa/core/theme/resi_tokens.dart';

/// Écran de bienvenue, au premier lancement : la photo de la maison en plein
/// écran, un voile noir léger en haut qui fonce vers le bas, et tout le
/// contenu groupé sous le pouce. Toujours en sombre, la photo l'impose.
@RoutePage()
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark(),
      child: Builder(
        builder: (context) {
          final t = context.tokens;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Scaffold(
              backgroundColor: t.overlay,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  const _Photo(),
                  // Voile : la maison reste lisible en haut, le texte se lit
                  // en bas.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, 0.35, 0.62, 1],
                        colors: [
                          t.overlay.withValues(alpha: 0.30),
                          t.overlay.withValues(alpha: 0.10),
                          t.overlay.withValues(alpha: 0.55),
                          t.overlay.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                  const _FloatingGlass(),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          _Eyebrow(label: 'welcome.eyebrow'.tr()),
                          const SizedBox(height: 16),
                          Text(
                            'welcome.title'.tr(),
                            style: context.text.displayLarge!.copyWith(
                              fontSize: 36,
                              height: 1.12,
                              letterSpacing: -0.6,
                              fontWeight: FontWeight.w600,
                              color: t.onOverlay,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'welcome.subtitle'.tr(),
                            style: context.text.bodyLarge!.copyWith(
                              height: 1.45,
                              color: t.onOverlay.withValues(alpha: 0.78),
                            ),
                          ),
                          const SizedBox(height: 44),
                          _SlideToStart(
                            onCompleted: () => context.router.replaceAll([
                              const LoginRoute(),
                            ]),
                          ),
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
    );
  }
}

/// La photo, décodée à la taille exacte de l'écran : l'image source est bien
/// plus grande, et la réduire au décodage avec un filtrage haut de gamme la
/// garde nette sans charger en mémoire des pixels qui ne s'afficheront pas.
class _Photo extends StatelessWidget {
  const _Photo();

  static const _asset = 'assets/images/resi/splash_screen.jpg';

  /// Dimensions de l'image source, pour calculer la taille de décodage.
  static const _sourceWidth = 3960.0;
  static const _sourceHeight = 2640.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // `cover` remplit l'écran : la hauteur affichée de l'image est la plus
    // grande des deux contraintes.
    final shownHeight = math.max(
      size.height,
      size.width * _sourceHeight / _sourceWidth,
    );
    final decodeHeight = math.min(shownHeight * dpr, _sourceHeight).round();

    return Image(
      image: ResizeImage(
        const AssetImage(_asset),
        height: decodeHeight,
        policy: ResizeImagePolicy.fit,
      ),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }
}

/// Quatre cadres de verre vides posés sur le haut de la photo : ils ne portent
/// rien, mais donnent l'impression que des cartes flottent sur la maison.
/// Chacun dérive doucement à son rythme ; « Réduire les animations » les
/// fige.
class _FloatingGlass extends StatefulWidget {
  const _FloatingGlass();

  @override
  State<_FloatingGlass> createState() => _FloatingGlassState();
}

class _FloatingGlassState extends State<_FloatingGlass>
    with SingleTickerProviderStateMixin {
  late final _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  /// Cadres en fractions de l'écran : gauche, haut, largeur, hauteur, rayon,
  /// et décalage de phase de la dérive. Les cadres opposés en diagonale ont
  /// la même taille ; tous sont espacés d'au moins 5 % de l'écran, assez pour
  /// ne jamais se toucher pendant la dérive (± 6 px).
  static const _panes = [
    // Diagonale haut gauche → bas droite : les deux bien longs.
    (x: 0.05, y: 0.05, w: 0.42, h: 0.24, r: 30.0, phase: 0.0),
    (x: 0.53, y: 0.30, w: 0.42, h: 0.24, r: 30.0, phase: 0.75),
    // Diagonale haut droite → bas gauche : longs, mais moins.
    (x: 0.53, y: 0.08, w: 0.42, h: 0.17, r: 28.0, phase: 0.25),
    (x: 0.05, y: 0.34, w: 0.42, h: 0.17, r: 28.0, phase: 0.5),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _drift,
        builder: (context, _) => Stack(
          children: [
            for (final p in _panes)
              Positioned(
                left: p.x * size.width,
                top:
                    p.y * size.height +
                    6 * math.sin((_drift.value + p.phase) * 2 * math.pi),
                width: p.w * size.width,
                height: p.h * size.height,
                child: _GlassPane(radius: p.r),
              ),
          ],
        ),
      ),
    );
  }
}

/// Un cadre de verre clair, sans flou : la photo reste nette au travers.
/// Seuls un voile à peine visible, un liseré lumineux plus vif en haut à
/// gauche et un reflet sur le bord supérieur disent qu'un cadre est posé.
class _GlassPane extends StatelessWidget {
  const _GlassPane({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    final white = context.tokens.onOverlay;
    return CustomPaint(
      foregroundPainter: _GlassRimPainter(radius: radius, color: white),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              white.withValues(alpha: 0.06),
              white.withValues(alpha: 0.015),
              white.withValues(alpha: 0.03),
            ],
          ),
        ),
      ),
    );
  }
}

/// Liseré en dégradé et reflet du haut : c'est lui qui donne l'épaisseur du
/// verre.
class _GlassRimPainter extends CustomPainter {
  _GlassRimPainter({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1),
      Radius.circular(radius),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.50),
            color.withValues(alpha: 0.10),
            color.withValues(alpha: 0.24),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
    // Reflet : une bande claire qui s'efface sous le bord supérieur.
    final shine = Rect.fromLTWH(0, 0, size.width, size.height * 0.45);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        shine,
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(radius),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.07), color.withValues(alpha: 0)],
        ).createShader(shine),
    );
  }

  @override
  bool shouldRepaint(_GlassRimPainter old) =>
      old.radius != radius || old.color != color;
}

/// Petite étiquette au-dessus du titre : un trait et un libellé espacé.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Container(width: 20, height: 1.5, color: t.onOverlay),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: context.text.labelMedium!.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
            color: t.onOverlay.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

/// Curseur « Glisser pour commencer » : la pastille se tire vers la droite
/// sur une piste en verre. Lâchée avant le bout, elle revient ; arrivée au
/// bout (ou lancée assez vite), elle valide. Les lecteurs d'écran le voient
/// comme un bouton qu'un double appui active.
class _SlideToStart extends StatefulWidget {
  const _SlideToStart({required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<_SlideToStart> createState() => _SlideToStartState();
}

class _SlideToStartState extends State<_SlideToStart>
    with SingleTickerProviderStateMixin {
  static const _height = 64.0;
  static const _inset = 6.0;
  static const _thumb = _height - _inset * 2;

  /// Part de la course au-delà de laquelle un lâcher valide.
  static const _threshold = 0.8;

  /// Vitesse (px/s) d'un lancer qui valide même avant le seuil.
  static const _flingVelocity = 900.0;

  /// Position de la pastille, de 0 (gauche) à 1 (bout de la piste).
  late final _progress = AnimationController(vsync: this);
  double _travel = 1;
  bool _done = false;

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_done) return;
    _progress.value += d.primaryDelta! / _travel;
  }

  void _onDragEnd(DragEndDetails d) {
    if (_done) return;
    final v = d.primaryVelocity ?? 0;
    if (_progress.value >= _threshold || v > _flingVelocity) {
      _complete();
    } else {
      _progress.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _complete() async {
    if (_done) return;
    _done = true;
    HapticFeedback.mediumImpact();
    await _progress.animateTo(
      1,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
    );
    if (mounted) widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final label = 'welcome.slide'.tr();

    return Semantics(
      button: true,
      label: label,
      onTap: _complete,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _travel = math.max(1, constraints.maxWidth - _thumb - _inset * 2);
          return SizedBox(
            height: _height,
            child: AnimatedBuilder(
              animation: _progress,
              builder: (context, _) {
                final p = _progress.value;
                final dx = p * _travel;
                return Stack(
                  children: [
                    // Piste en verre.
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: t.onOverlay.withValues(alpha: 0.14),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: t.onOverlay.withValues(alpha: 0.22),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Traînée laissée derrière la pastille.
                    Positioned(
                      left: _inset,
                      top: _inset,
                      bottom: _inset,
                      width: _thumb + dx,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: t.onOverlay.withValues(alpha: 0.18 * p),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    // Libellé, qui s'efface à mesure qu'on glisse.
                    Positioned.fill(
                      left: _thumb + _inset * 2,
                      child: Opacity(
                        opacity: (1 - p * 1.8).clamp(0.0, 1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: t.onOverlay,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              LucideIcons.chevronsRight,
                              size: 20,
                              color: t.onOverlay.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Pastille à tirer.
                    Positioned(
                      left: _inset + dx,
                      top: _inset,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: _onDragUpdate,
                        onHorizontalDragEnd: _onDragEnd,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: t.foreground,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox.square(
                            dimension: _thumb,
                            child: Icon(
                              LucideIcons.arrowRight,
                              size: 22,
                              color: t.background,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
